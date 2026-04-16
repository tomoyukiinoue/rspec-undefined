# frozen_string_literal: true

RSpec.describe RSpec::Undefined do
  it "バージョン番号を持つ" do
    expect(RSpec::Undefined::VERSION).not_to be_nil
  end

  it "Registry シングルトンを返す" do
    expect(RSpec::Undefined.registry).to be(RSpec::Undefined.registry)
  end

  it "configure で report_format を設定できる" do
    original = RSpec::Undefined.configuration.report_format
    begin
      RSpec::Undefined.configure { |c| c.report_format = :yaml }
      expect(RSpec::Undefined.configuration.report_format).to eq(:yaml)
    ensure
      RSpec::Undefined.configure { |c| c.report_format = original }
    end
  end
end
