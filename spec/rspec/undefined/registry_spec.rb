# frozen_string_literal: true

require "rspec/undefined/entry"
require "rspec/undefined/registry"

RSpec.describe RSpec::Undefined::Registry do
  subject(:registry) { described_class.new }

  let(:entry) do
    RSpec::Undefined::Entry.new(kind: :matcher, matcher: "be_undefined",
                                location: "spec/x.rb:1")
  end

  it "追加と取得" do
    registry.add(entry)
    expect(registry.all.size).to eq(1)
    expect(registry.all.first).to be(entry)
  end

  it "clear で空になる" do
    registry.add(entry)
    registry.clear
    expect(registry.all).to eq([])
  end

  it "スレッドセーフ" do
    threads = 20.times.map do
      Thread.new do
        10.times { registry.add(entry) }
      end
    end
    threads.each(&:join)
    expect(registry.all.size).to eq(200)
  end

  describe ".instance" do
    it "シングルトン" do
      expect(described_class.instance).to be(described_class.instance)
    end
  end
end
