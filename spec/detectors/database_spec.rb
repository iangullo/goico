require 'spec_helper'

RSpec.describe Goico::Detectors::Database do
  let(:detector) { described_class.new(app_path) }

  describe '#detect' do
    context 'with PostgreSQL configuration' do
      let(:app_path) { create_temp_rails_app('config/database.yml' => <<~YAML) }
        production:
          adapter: postgresql
          database: app_production
      YAML

      it 'detects PostgreSQL' do
        expect(detector.detect).to eq(:postgresql)
      end
    end

    context 'with MySQL configuration' do
      let(:app_path) { create_temp_rails_app('config/database.yml' => <<~YAML) }
        production:
          adapter: mysql2
          database: app_production
      YAML

      it 'detects MySQL' do
        expect(detector.detect).to eq(:mysql)
      end
    end

    context 'with SQLite configuration' do
      let(:app_path) { create_temp_rails_app('config/database.yml' => <<~YAML) }
        production:
          adapter: sqlite3
          database: db/production.sqlite3
      YAML

      it 'detects SQLite' do
        expect(detector.detect).to eq(:sqlite)
      end
    end

    context 'with no database.yml' do
      let(:app_path) { create_temp_rails_app('config/database.yml' => nil) }

      it 'defaults to PostgreSQL' do
        expect(detector.detect).to eq(:postgresql)
      end
    end

    context 'with empty database.yml' do
      let(:app_path) { create_temp_rails_app('config/database.yml' => '') }

      it 'defaults to PostgreSQL' do
        expect(detector.detect).to eq(:postgresql)
      end
    end
  end

  describe '#system_dependencies' do
    it 'returns PostgreSQL dependencies for PostgreSQL' do
      allow(detector).to receive(:detect).and_return(:postgresql)
      deps = detector.system_dependencies
      expect(deps).to include('postgresql')
      expect(deps).to include('postgresql-contrib')
      expect(deps).to include('libpq-dev')
    end

    it 'returns MySQL dependencies for MySQL' do
      allow(detector).to receive(:detect).and_return(:mysql)
      deps = detector.system_dependencies
      expect(deps).to include('mysql-server')
      expect(deps).to include('libmysqlclient-dev')
    end

    it 'returns SQLite dependencies for SQLite' do
      allow(detector).to receive(:detect).and_return(:sqlite)
      deps = detector.system_dependencies
      expect(deps).to include('libsqlite3-dev')
    end
  end
end