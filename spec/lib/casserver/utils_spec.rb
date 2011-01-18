require 'spec/spec_helper'

require 'casserver'
require 'casserver/utils'

describe CASServer::Utils, '#random_string(max_length = 29)' do
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
