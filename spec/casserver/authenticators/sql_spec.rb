require 'spec_helper'

describe CASServer::Authenticators::SQL do
  let(:options) do
    {
      auth_index: 0,
      user_table: 'users',
      username_column: 'username',
      password_column: 'password',
      database: {
        adapter: 'mysql2',
        database: 'casserver',
        username: 'root',
        password: 'password',
        host: 'localhost'
      }
    }
  end
  let(:connection) { double('Connection', run_callbacks: nil) }
  let(:connection_pool) { double('ConnectionPool',
                                 connections: [connection],
                                 checkin: nil) }

  before do
    load_server('default_config') if $LOG.nil? # ensure logger is present
    ActiveRecord::Base.stub(:establish_connection)
    ActiveRecord::Base.stub(:connection).and_return(connection)
    ActiveRecord::Base.stub(:connection_pool).and_return(connection_pool)
    CASServer::Authenticators::SQL.setup(options)
  end

  describe '#validate' do
    let(:auth) { CASServer::Authenticators::SQL.new }
    let(:username) { 'dave' }
    let(:password) { 'secret' }
    let(:user_model) { CASServer::Authenticators::SQL.user_models[0] }

    before do
      auth.configure(HashWithIndifferentAccess.new(options))
    end

    context 'when credentials match a user in the database' do
      it 'returns true' do
        conditions = ['username = ? AND password = ?', username, password]
        user_model.should_receive(:find).with(:all, conditions: conditions)
          .and_return([:user])
        credentials = {
          username: username,
          password: password
        }
        expect(auth.validate(credentials)).to be true
      end
    end

    context 'when credentials do not match a user in the database' do
      it 'returns false' do
        conditions = ['username = ? AND password = ?', username, password]
        user_model.should_receive(:find).with(:all, conditions: conditions)
          .and_return([])
        credentials = {
          username: username,
          password: password
        }
        expect(auth.validate(credentials)).to be false
      end
    end

    context 'when many SQL authenticators have been setup' do
      let(:alt_options) do
        {
          auth_index: 1,
          user_table: 'users',
          username_column: 'username',
          password_column: 'password',
          database: {
            adapter: 'mysql2',
            database: 'casserver',
            username: 'root',
            password: 'password',
            host: 'localhost'
          }
        }
      end

      before do
        CASServer::Authenticators::SQL.setup(alt_options)
      end

      it 'chooses the correct user model based upon auth_index' do
        # Original authenticator
        conditions = ['username = ? AND password = ?', username, password]
        user_model.should_receive(:find).with(:all, conditions: conditions)
          .and_return([:user])
        credentials = {
          username: username,
          password: password
        }
        expect(auth.validate(credentials)).to be true

        # Alternate authenticator, different credentials, different user model
        alt_auth = CASServer::Authenticators::SQL.new
        alt_user_model = CASServer::Authenticators::SQL.user_models[1]
        alt_username = 'dan'
        conditions = ['username = ? AND password = ?', alt_username, password]
        alt_user_model.should_receive(:find).with(:all, conditions: conditions)
          .and_return([:user])
        alt_credentials = {
          username: alt_username,
          password: password
        }
        alt_auth.configure(HashWithIndifferentAccess.new(alt_options))
        expect(alt_auth.validate(alt_credentials)).to be true
      end
    end
  end
end
