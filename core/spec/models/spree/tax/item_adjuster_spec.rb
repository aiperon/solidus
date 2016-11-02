require 'spec_helper'

RSpec.describe Spree::Tax::ItemAdjuster do
  subject(:adjuster) { described_class.new(item) }
  let(:order) { create(:order) }
  let(:item) { Spree::LineItem.new(order: order) }

  def tax_adjustments
    item.adjustments.tax.to_a
  end

  describe 'initialization' do
    it 'sets order to item order' do
      expect(adjuster.order).to eq(item.order)
    end

    it 'sets adjustable' do
      expect(adjuster.item).to eq(item)
    end
  end

  describe '#adjust!' do
    before do
      expect(order).to receive(:tax_address).at_least(:once).and_return(address)
    end

    context 'when the order has no tax zone' do
      let(:address) { Spree::Tax::TaxLocation.new }

      it 'creates no adjustments' do
        adjuster.adjust!
        expect(tax_adjustments).to eq([])
      end
    end

    context 'when the order has an address thats taxable' do
      let(:item) { build_stubbed :line_item, order: order }
      let(:address) { order.tax_address }

      before do
        expect(Spree::TaxRate).to receive(:for_address).with(order.tax_address).and_return(rates_for_order_zone)
      end

      context 'when there are no matching rates' do
        let(:rates_for_order_zone) { [] }

        it 'returns no adjustments' do
          adjuster.adjust!
          expect(tax_adjustments).to eq([])
        end
      end

      context 'when there are matching rates for the zone' do
        context 'and all rates have the same tax category as the item' do
          let(:item_tax_category) { build_stubbed(:tax_category) }
          let(:rate_1) { create :tax_rate, tax_category: item_tax_category }
          let(:rate_2) { create :tax_rate }
          let(:rates_for_order_zone) { [rate_1, rate_2] }

          before { allow(item).to receive(:tax_category).and_return(item_tax_category) }

          it 'creates an adjustment for every matching rate' do
            adjuster.adjust!
            expect(tax_adjustments.length).to eq(1)
          end
        end
      end
    end
  end
end
