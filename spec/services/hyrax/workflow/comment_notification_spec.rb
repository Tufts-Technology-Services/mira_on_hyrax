# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Workflow::CommentNotification, :workflow, :clean do
  let(:depositor) { FactoryBot.create(:user) }
  let!(:admin)    { FactoryBot.create(:admin) }
  let(:work)      { FactoryBot.actor_create(:pdf, depositor: depositor.user_key, user: depositor) }

  let(:recipients) do
    { 'to' => [depositor] }
  end

  let(:notification) do
    work_global_id = work.to_global_id.to_s
    entity = Sipity::Entity.where(proxy_for_global_id: work_global_id).first

    # TODO: make sure no where else we are sending strings in as comments
    # TODO: Does this test need a comment?
    described_class.new(entity, nil, depositor, recipients)
  end

  it "includes a full url in the message" do
    expect(notification).to be_instance_of(described_class)
    expect(notification.message).to match(/http/)
  end
  it "can find depositor" do
    expect(notification.depositor).to be_instance_of(::User)
    expect(notification.depositor.user_key).to eq depositor.user_key
  end
  it "can find admins" do
    expect(notification.admins).to be_instance_of(Array)
    expect(notification.admins.pluck(:id)).to contain_exactly(admin.id)
  end
  it "sends notifications to the depositor, application admins and no one else" do
    expect(notification.recipients["to"].pluck(Hydra.config.user_key_field)).to contain_exactly(depositor.user_key, admin.user_key)
  end
end
