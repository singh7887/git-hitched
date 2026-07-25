module Admin
  class RecommendationsController < BaseController
    before_action :set_recommendation, only: [ :edit, :update, :destroy ]

    def index
      @recommendations = Recommendation.ordered
    end

    def new
      @recommendation = Recommendation.new(published: true)
    end

    def create
      @recommendation = Recommendation.new(recommendation_params)
      if @recommendation.save
        redirect_to admin_recommendations_path, notice: "Place added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @recommendation.update(recommendation_params)
        redirect_to admin_recommendations_path, notice: "Place updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @recommendation.destroy
      redirect_to admin_recommendations_path, notice: "Place removed."
    end

    private

    def set_recommendation
      @recommendation = Recommendation.find(params[:id])
    end

    def recommendation_params
      params.require(:recommendation).permit(:name, :category, :location, :note, :url, :sort_order, :published)
    end
  end
end
