require 'rails_helper'

RSpec.describe Course, type: :model do
  let!(:instance) { create(:instance) }
  with_tenant(:instance) do
    context 'when title is not present' do
      subject { build(:course, title: '') }

      it { is_expected.not_to be_valid }
    end

    context 'when course is created' do
      subject { Course.new }

      it { is_expected.not_to be_published }
      it { is_expected.not_to be_opened }
    end
  end
end
