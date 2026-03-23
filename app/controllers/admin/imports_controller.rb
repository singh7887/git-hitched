require "csv"
require "net/http"

module Admin
  class ImportsController < BaseController
    def new
      @sheet_url = ENV["GOOGLE_SHEET_URL"]
    end

    def create
      sheet_url = params[:sheet_url]&.strip
      if sheet_url.blank?
        return redirect_to admin_import_path, alert: "Please provide a Google Sheets URL."
      end

      csv_url = to_csv_export_url(sheet_url)
      unless csv_url
        return redirect_to admin_import_path, alert: "Invalid Google Sheets URL. Use a URL like https://docs.google.com/spreadsheets/d/SHEET_ID/..."
      end

      csv_data = fetch_csv(csv_url)
      unless csv_data
        return redirect_to admin_import_path, alert: "Could not fetch the sheet. Make sure it's published to the web or shared as 'Anyone with the link'."
      end

      imported = 0
      errors = []

      CSV.parse(csv_data, headers: true, header_converters: :symbol) do |row|
        next if row[:email].blank?

        invite = Invite.find_or_create_by!(email: row[:email].strip.downcase) do |i|
          i.name = row[:name] || row[:household_name]
        end

        full_name = (row[:name] || row[:household_name] || "Guest").strip

        invite.guests.find_or_create_by!(first_name: full_name) do |g|
          g.is_primary = true
        end

        imported += 1
      rescue StandardError => e
        errors << "Row error: #{e.message}"
      end

      notice = "Imported #{imported} invite(s) from Google Sheet."
      if errors.any?
        notice += " #{errors.size} warning(s): #{errors.first(3).join('; ')}"
        notice += " (and #{errors.size - 3} more)" if errors.size > 3
      end
      redirect_to admin_invites_path, notice: notice
    end

    private

    def to_csv_export_url(url)
      match = url.match(%r{/spreadsheets/d/([a-zA-Z0-9_-]+)})
      return nil unless match

      sheet_id = match[1]

      gid_match = url.match(/gid=(\d+)/)
      gid = gid_match ? gid_match[1] : "0"

      "https://docs.google.com/spreadsheets/d/#{sheet_id}/export?format=csv&gid=#{gid}"
    end

    def fetch_csv(url)
      uri = URI(url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 15) do |http|
        request = Net::HTTP::Get.new(uri)
        http.request(request)
      end

      if response.is_a?(Net::HTTPRedirection)
        uri = URI(response["location"])
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 15) do |http|
          http.request(Net::HTTP::Get.new(uri))
        end
      end

      response.is_a?(Net::HTTPSuccess) ? response.body : nil
    rescue StandardError
      nil
    end
  end
end
