require 'spec_helper'

describe Virtus::Attribute::Collection, '#coerce' do
  subject { object.coerce(input) }

  context 'when input is an array' do
    context 'when member type is a primitive' do
      fake(:coercer)     { Virtus::Attribute::Coercer }
      fake(:member_type) { Virtus::Attribute }

      let(:member_primitive) { Integer }
      let(:input)            { ['1', '2'] }

      let(:object) {
        described_class.build(Array[member_primitive], :coercer => coercer, :member_type => member_type)
      }

      it 'uses coercer to coerce members' do
        mock(coercer).call(input) { input }
        mock(member_type).finalize { member_type }
        mock(member_type).coerce('1') { 1 }
        mock(member_type).coerce('2') { 2 }

        expect(subject).to eq([1, 2])

        expect(member_type).to have_received.coerce('1')
        expect(member_type).to have_received.coerce('2')
      end
    end

    context 'when member type is an EV' do
      let(:member_primitive) { Struct.new(:id) }
      let(:input)            { [1, 2] }
      let(:object)           { described_class.build(Array[member_primitive]) }

      it 'coerces members' do
        expect(subject).to eq([member_primitive.new(1), member_primitive.new(2)])
      end
    end

    context 'when member type is a hash with key/value coercion' do
      let(:member_primitive) { Hash[String => Integer] }
      let(:member_attribute) { Virtus::Attribute.build(member_primitive) }
      let(:input)            { [{:one => '1'}, {:two => '2'}] }
      let(:output)           { [member_attribute.coerce(input.first), member_attribute.coerce(input.last)] }
      let(:object)           { described_class.build(Array[member_primitive]) }

      it 'coerces members' do
        expect(subject).to eq(output)
      end
    end
  end

  context 'when input is nil' do
    let(:input) { nil }

    fake(:coercer)     { Virtus::Attribute::Coercer }
    fake(:member_type) { Virtus::Attribute }

    let(:member_primitive) { Integer }

    let(:object) {
      described_class.build(
        Array[member_primitive], coercer: coercer, member_type: member_type
      )
    }

    it 'returns nil' do
      mock(coercer).call(input) { input }

      expect(subject).to be(input)
    end
  end

  context 'when primitive is ActiveRecord::Relation' do
    before do
      relation_class = Class.new do
        include Enumerable

        def initialize(*args)
          raise ArgumentError, 'expected 1' if args.empty?
        end

        def each
        end
      end

      @active_record_defined = Object.const_defined?(:ActiveRecord)
      @active_record_original = Object.const_get(:ActiveRecord) if @active_record_defined

      Object.const_set(:ActiveRecord, Module.new)
      ActiveRecord.const_set(:Relation, relation_class)
    end

    after do
      ActiveRecord.send(:remove_const, :Relation) if ActiveRecord.const_defined?(:Relation)

      if @active_record_defined
        Object.send(:remove_const, :ActiveRecord)
        Object.const_set(:ActiveRecord, @active_record_original)
      else
        Object.send(:remove_const, :ActiveRecord) if Object.const_defined?(:ActiveRecord)
      end
    end

    let(:object) { Virtus::Attribute.build(ActiveRecord::Relation) }

    context 'when input is an array' do
      let(:input) { [] }

      it 'passes through arrays without constructing a relation' do
        expect(subject).to eq([])
      end
    end

    context 'when input is a relation instance' do
      let(:input) { ActiveRecord::Relation.new(:dummy) }

      it 'passes through relation instances' do
        expect(subject).to equal(input)
      end
    end
  end
end
