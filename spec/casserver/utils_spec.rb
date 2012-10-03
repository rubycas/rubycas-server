# encoding: UTF-8
require 'spec_helper'

module CASServer
end
require 'casserver/utils'

describe CASServer::Utils, '#random_string(max_length = 29)' do
  before do
    load_server("default_config")
    reset_spec_database
  end
  
  context 'when max length is not passed in' do
    it 'should return a random string of length 29' do
      subject.random_string.length.should == 29
    end
  end

  context 'when max length is passed in' do
    it 'should return a random string of the desired length' do
      subject.random_string(30).length.should == 30
    end
  end

  it 'should include the letter r in the random string' do
    subject.random_string.should include 'r'
  end

  it 'should return a random string' do
    random_string = subject.random_string
    another_random_string = subject.random_string
    random_string.should_not == another_random_string
  end
end

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
