require 'spec_helper'

describe 'Virtus constructor keyword args' do
  subject(:klass) do
    Class.new do
      include Virtus.model

      attribute :foo, String
      attribute :bar, String
    end
  end

  it 'accepts keyword args' do
    object = klass.new(foo: 'a')
    expect(object.foo).to eq('a')
  end

  it 'merges positional hash and keyword args' do
    object = klass.new({ :foo => 'a' }, bar: 'b')
    expect(object.foo).to eq('a')
    expect(object.bar).to eq('b')
  end
end
