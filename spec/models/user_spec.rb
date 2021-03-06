require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(30) }
  end

  describe "associations" do
    it { should have_one_attached(:avatar_image) }
  end
end
