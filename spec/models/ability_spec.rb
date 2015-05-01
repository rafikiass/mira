require 'spec_helper'
require "cancan/matchers"

describe Ability do
  subject { Ability.new(user) }

  describe "an admin user" do
    let(:user) { FactoryGirl.create(:admin) }
    let(:audio) { TuftsAudio.create!(title: 'test audio', displays: ['dl']) }

    it "has abilities" do
      expect(subject).to be_able_to(:read, SolrDocument)

      expect(subject).to be_able_to(:index, Role)
      expect(subject).to be_able_to(:create, Role)
      expect(subject).to be_able_to(:show, Role)
      expect(subject).to be_able_to(:add_user, Role)
      expect(subject).to be_able_to(:remove_user, Role)

      expect(subject).to be_able_to(:index, Batch)
      expect(subject).to be_able_to(:new_template_import, Batch)
      expect(subject).to be_able_to(:new_xml_import, Batch)
      expect(subject).to be_able_to(:create, Batch)
      expect(subject).to be_able_to(:show, Batch)
      expect(subject).to be_able_to(:edit, Batch)
      expect(subject).to be_able_to(:update, Batch)

      expect(subject).to be_able_to(:create, DepositType)
      expect(subject).to be_able_to(:read, DepositType)
      expect(subject).to be_able_to(:update, DepositType)
      expect(subject).to be_able_to(:destroy, DepositType)
      expect(subject).to be_able_to(:export, DepositType)

      expect(subject).to be_able_to(:create, TuftsAudio)
      expect(subject).to be_able_to(:edit, audio)
      expect(subject).to be_able_to(:update, audio)
      expect(subject).to be_able_to(:review, audio)
      expect(subject).to be_able_to(:publish, audio)
      expect(subject).to be_able_to(:unpublish, audio)
      expect(subject).to be_able_to(:destroy, audio)
    end
  end

  describe "a non-admin user" do
    let(:user) { FactoryGirl.create(:user) }

    it "has certain rights" do
      expect(subject).to_not be_able_to(:index, Role)
      expect(subject).to_not be_able_to(:create, Role)
      expect(subject).to_not be_able_to(:show, Role)
      expect(subject).to_not be_able_to(:add_user, Role)
      expect(subject).to_not be_able_to(:remove_user, Role)

      expect(subject).to_not be_able_to(:index, Batch)
      expect(subject).to_not be_able_to(:new_template_import, Batch)
      expect(subject).to_not be_able_to(:new_xml_import, Batch)
      expect(subject).to_not be_able_to(:create, Batch)
      expect(subject).to_not be_able_to(:show, Batch)
      expect(subject).to_not be_able_to(:edit, Batch)
      expect(subject).to_not be_able_to(:update, Batch)

      expect(subject).to_not be_able_to(:create, DepositType)
      expect(subject).to_not be_able_to(:read, DepositType)
      expect(subject).to_not be_able_to(:update, DepositType)
      expect(subject).to_not be_able_to(:destroy, DepositType)
      expect(subject).to_not be_able_to(:export, DepositType)

      expect(subject).to be_able_to(:create, Contribution)
    end

    context "working on TuftsPdf" do
      context "that they own" do
        let(:self_deposit) { FactoryGirl.create(:tufts_pdf, user: user) }

        it "should grant access" do
          expect(subject).to     be_able_to(:read, self_deposit)
          expect(subject).to     be_able_to(:update, self_deposit)
          expect(subject).to     be_able_to(:destroy, self_deposit)
          expect(subject).to_not be_able_to(:publish, self_deposit)
          expect(subject).to_not be_able_to(:review, self_deposit)
        end
      end

      describe "that they don't own" do
        let(:self_deposit) { FactoryGirl.create(:tufts_pdf) }

        it "should not grant access" do
          expect(subject).to_not be_able_to(:read, self_deposit)
          expect(subject).to_not be_able_to(:update, self_deposit)
          expect(subject).to_not be_able_to(:destroy, self_deposit)
          expect(subject).to_not be_able_to(:publish, self_deposit)
          expect(subject).to_not be_able_to(:review, self_deposit)
        end
      end
    end

    describe "working on TuftsAudio" do
      it { is_expected.not_to be_able_to(:create, TuftsAudio) }

      context "that they own" do
        let(:audio) { FactoryGirl.create(:tufts_audio, user: user) }
        it "should grant access" do
          expect(subject).to     be_able_to(:edit, audio)
          expect(subject).to     be_able_to(:update, audio)
          expect(subject).to_not be_able_to(:review, audio)
          expect(subject).to_not be_able_to(:publish, audio)
          expect(subject).to     be_able_to(:destroy, audio)
        end
      end

      context "that they don't own" do
        let(:audio) { FactoryGirl.create(:tufts_audio) }
        it "shouldn't grant access" do
          expect(subject).to_not be_able_to(:edit, audio)
          expect(subject).to_not be_able_to(:update, audio)
          expect(subject).to_not be_able_to(:review, audio)
          expect(subject).to_not be_able_to(:publish, audio)
          expect(subject).to_not be_able_to(:destroy, audio)
        end
      end
    end
  end

  describe "a non-authenticated user" do
    let(:user) { User.new }
    let(:pdf) { TuftsPdf.create!(title: 'test pdf', read_groups: ['public'], displays: ['dl']) }
    let(:audio) do
      TuftsAudio.new(title: 'foo', displays: ['dl']).tap do |audio|
        audio.read_groups = ['public']
        audio.save!
      end
    end

    it "should give some access" do
      expect(subject).to_not be_able_to(:index, Role)
      expect(subject).to_not be_able_to(:create, Role)
      expect(subject).to_not be_able_to(:show, Role)
      expect(subject).to_not be_able_to(:add_user, Role)
      expect(subject).to_not be_able_to(:remove_user, Role)

      expect(subject).to_not be_able_to(:create, DepositType)
      expect(subject).to_not be_able_to(:read, DepositType)
      expect(subject).to_not be_able_to(:update, DepositType)
      expect(subject).to_not be_able_to(:destroy, DepositType)
      expect(subject).to_not be_able_to(:export, DepositType)

      expect(subject).to be_able_to(:read, pdf.pid)

      expect(subject).to_not be_able_to(:create, Contribution)

      expect(subject).to be_able_to(:read, audio)
    end
  end
end
