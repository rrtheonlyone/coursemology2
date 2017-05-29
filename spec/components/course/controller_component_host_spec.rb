# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Course::ControllerComponentHost, type: :controller do
  controller(Course::Controller) do
  end

  class self::DummyCourseModule < SimpleDelegator
    include Course::ControllerComponentHost::Component

    NORMAL_SIDEBAR_ITEM = {
      key: :normal_item,
      title: 'DummyCourseModule',
      type: :normal,
      weight: 1,
      unread: -1
    }.freeze

    ADMIN_SIDEBAR_ITEM = {
      key: :admin_item,
      title: 'DummyCourseModule',
      type: :admin,
      weight: 10,
      unread: -1
    }.freeze

    SETTINGS_SIDEBAR_ITEM = {
      title: 'DummyCourseModule',
      type: :settings,
      weight: 1
    }.freeze

    def sidebar_items
      [NORMAL_SIDEBAR_ITEM, ADMIN_SIDEBAR_ITEM, SETTINGS_SIDEBAR_ITEM]
    end
  end

  class self::DummyGamifiedCourseModule
    include Course::ControllerComponentHost::Component

    def self.gamified?
      true
    end

    def initialize(*)
    end
  end

  class self::DummyCoreCourseModule
    include Course::ControllerComponentHost::Component

    def self.can_be_disabled?
      false
    end

    def initialize(*)
    end
  end

  class Course::Settings::DummyCourseModule
    def initialize(*)
    end
  end

  let!(:instance) { create(:instance) }
  with_tenant(:instance) do
    let(:user) { create(:administrator) }
    before { sign_in(user) }
    let(:course) { create(:course, instance: instance) }
    before { controller.instance_variable_set(:@course, course) }

    let(:component_host) do
      Course::ControllerComponentHost.new(instance.settings, course.settings, controller)
    end
    let(:default_enabled_components) do
      Course::ControllerComponentHost.components.select(&:enabled_by_default?)
    end

    describe 'Components' do
      subject do
        component_host.components.find do |component|
          component.class == self.class::DummyCourseModule
        end
      end

      it 'has an autogenerated key' do
        expect(subject.key).to eq(subject.class.name.underscore.tr('/', '_').to_sym)
      end

      describe '.settings_class' do
        context 'when the settings interface class is defined' do
          it 'returns it' do
            expect(subject.settings_class).to be(Course::Settings::DummyCourseModule)
          end
        end

        context 'when the settings interface class is not defined' do
          subject do
            component_host.components.find do |component|
              component.class == self.class::DummyGamifiedCourseModule
            end
          end

          it 'returns nil' do
            expect(subject.settings_class).to be_nil
          end
        end
      end

      describe '#settings' do
        context 'when the settings interface class is defined' do
          it 'returns a settings object' do
            expect(subject.settings.class).to be(Course::Settings::DummyCourseModule)
          end
        end

        context 'when the settings interface class is not defined' do
          subject do
            component_host.components.find do |component|
              component.class == self.class::DummyGamifiedCourseModule
            end
          end

          it 'returns nil' do
            expect(subject.settings).to be_nil
          end
        end
      end
    end

    describe '.disableable_components' do
      subject { Course::ControllerComponentHost.disableable_components }

      it 'does not include components that cannot be disabled' do
        expect(subject).not_to include(self.class::DummyCoreCourseModule)
      end
    end

    describe '#initialize' do
      it 'instantiates all enabled components' do
        expect(self.class::DummyCourseModule).to receive(:new).and_call_original
        component_host
      end
    end

    describe '#components' do
      subject { component_host.components }

      it 'includes instances of every enabled component' do
        expect(subject.map(&:class)).to contain_exactly(*component_host.enabled_components)
      end

      it 'memoises its result' do
        expect(component_host.components).to be(subject)
      end
    end

    describe '#[]' do
      subject { component_host }

      context 'when the key specified does not exist' do
        it 'returns nil' do
          expect(subject['i_do_not_exist']).to be_nil
        end
      end

      context 'when the key provided is a string' do
        it 'returns the correct component' do
          expect(subject[self.class::DummyCourseModule.key.to_s]).to \
            be_a(self.class::DummyCourseModule)
        end
      end

      context 'when the key provided is a symbol' do
        it 'returns the correct component' do
          expect(subject[self.class::DummyCourseModule.key.to_sym]).to \
            be_a(self.class::DummyCourseModule)
        end
      end
    end

    describe '#enabled_components' do
      subject { component_host.enabled_components }

      it 'memoises its result' do
        expect(component_host.enabled_components).to be(subject)
      end

      context 'without preferences' do
        it 'returns the default enabled components' do
          expect(subject.count).to eq(default_enabled_components.count)
          default_enabled_components.each do |m|
            expect(subject.include?(m)).to be_truthy
          end
        end
      end

      context 'with preferences' do
        let(:sample_component) { default_enabled_components.first }
        context 'disable a component in course' do
          before { course.settings(sample_component.key).enabled = false }

          it 'does not include the disabled component' do
            expect(subject.include?(sample_component)).to be_falsey
          end
        end

        context 'disable a component in instance' do
          before { instance.settings(sample_component.key).enabled = false }

          it 'does not include the disabled component' do
            expect(subject.include?(sample_component)).to be_falsey
          end
        end

        context 'enable a component' do
          before { course.settings(sample_component.key).enabled = true }

          it 'includes the disabled component' do
            expect(subject.include?(sample_component)).to be_truthy
          end
        end
      end
    end

    describe '#course_available_components' do
      subject { component_host.course_available_components }
      context 'when the gamified flag for the course is set to false' do
        let(:course) { create(:course, instance: instance, gamified: false) }

        it 'does not include gamified components' do
          expect(subject).not_to include(self.class::DummyGamifiedCourseModule)
        end
      end
    end

    describe '#course_disableable_components' do
      subject { component_host.course_disableable_components }
      let(:course) { create(:course, instance: instance) }

      it 'does not include components that cannot be disabled' do
        expect(subject).not_to include(self.class::DummyCoreCourseModule)
      end
    end

    describe '#sidebar_items' do
      subject { component_host.sidebar_items }
      context 'when there are no components included' do
        it 'returns an empty array' do
          allow(component_host).to receive(:components).and_return([])
          expect(subject).to eq([])
        end
      end

      it "gathers all modules' sidebar items" do
        expect(subject).to include(self.class::DummyCourseModule::NORMAL_SIDEBAR_ITEM)
        expect(subject).to include(self.class::DummyCourseModule::ADMIN_SIDEBAR_ITEM)
        expect(subject).to include(self.class::DummyCourseModule::SETTINGS_SIDEBAR_ITEM)
      end
    end
  end
end
