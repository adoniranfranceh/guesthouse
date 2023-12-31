class PriceCustomization < ApplicationRecord
  belongs_to :room

  validates :season_name, :season, :start_date, :end_date, :daily_rate, presence: true
  validate :no_date_overlap, :date_end_is_later, :validate_daily_rate_for_high_season,
           :validate_daily_rate_for_low_season

  enum season: { high_season: 0, low_season: 5 }

  def validate_daily_rate_for_high_season
    if high_season? && daily_rate < room.daily_rate
      self.errors.add(:daily_rate, "só pode ser menor que à Diária Padrão durante se for Temporada Baixa")
    end
  end

  def validate_daily_rate_for_low_season
    if self.low_season? && self.daily_rate > room.daily_rate
      self.errors.add(:daily_rate, "só pode ser maior que à Diária Padrão se for Temporada Alta")
    end
  end

  private

  def date_end_is_later
    if self.start_date.present? && self.end_date.present? && self.start_date >= self.end_date
      errors.add(:end_date, 'não pode ser anterior ou igual à data de início')
    end
  end

  def no_date_overlap
    return nil unless room.present?
    overlapping_customizations = room.price_customizations.where.not(id: self.id).where(
      "(? <= end_date) AND (? >= start_date)",
      self.start_date, self.end_date
    )

    if overlapping_customizations.exists?
      self.errors.add(:base, "O intervalo de datas não pode se sobrepor a outros preços personalizados.")
    end
  end
end
