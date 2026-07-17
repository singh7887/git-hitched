module StageHelper
  # Pipeline order for the households CRM view.
  STAGE_ORDER = %i[not_sent awaiting attending declined skipped].freeze

  STAGE_META = {
    not_sent:  { label: "Not sent",  color: "var(--color-text-muted)" },
    awaiting:  { label: "Awaiting",  color: "var(--color-gold)" },
    attending: { label: "Attending", color: "var(--color-success)" },
    declined:  { label: "Declined",  color: "var(--color-error)" },
    skipped:   { label: "Skipped",   color: "var(--color-text-muted)" }
  }.freeze

  def stage_label(stage)
    STAGE_META.dig(stage.to_sym, :label) || stage.to_s.titleize
  end

  # Small rounded status badge (matches the side-badge pill styling in the list).
  def stage_pill(stage)
    meta = STAGE_META[stage.to_sym] || { label: stage.to_s.titleize, color: "var(--color-text-muted)" }
    content_tag(:span, meta[:label],
      style: "font-size: var(--text-xs); font-weight: 600; padding: 2px 8px; " \
             "border-radius: 999px; white-space: nowrap; color: #{meta[:color]}; " \
             "background: var(--color-bg-tertiary);")
  end
end
