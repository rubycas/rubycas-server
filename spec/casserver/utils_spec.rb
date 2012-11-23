# encoding: UTF-8
require 'spec_helper'

module CASServer
end
require 'casserver/utils'

describe CASServer::Utils, '#log_controller_action(controller, params)' do
  let(:params) { {} }
  let(:params_with_password) { { 'password' => 'test' } }
  let(:params_with_password_filtered) { { 'password' => '******' } }

  it 'should log the controller action' do
    $LOG.should_receive(:debug).with 'Processing application::instance_eval {}'

    subject.log_controller_action('application', params)
  end

  it 'should filter password parameters in the log' do
    $LOG.should_receive(:debug).with "Processing application::instance_eval #{params_with_password_filtered.inspect}"

    subject.log_controller_action('application', params_with_password)
  end
end
