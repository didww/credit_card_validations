require_relative 'test_helper'

class ExpiringCard
  include ActiveModel::Model
  attr_accessor :expiration

  validates :expiration, credit_card_expiration: true, allow_blank: true
end

describe ActiveModel::Validations::CreditCardExpirationValidator do
  let(:future) { (Date.today >> 12).strftime('%m/%y') }
  let(:past)   { (Date.today << 12).strftime('%m/%y') }

  it 'accepts a future MM/YY date' do
    expect(ExpiringCard.new(expiration: future).valid?).must_equal true
  end

  it 'rejects a past MM/YY date' do
    card = ExpiringCard.new(expiration: past)
    expect(card.valid?).must_equal false
    expect(card.errors[:expiration]).wont_be_empty
  end

  it 'rejects unparseable input' do
    expect(ExpiringCard.new(expiration: 'garbage').valid?).must_equal false
    expect(ExpiringCard.new(expiration: '13/27').valid?).must_equal false
  end

  it 'allows blank input via :allow_blank' do
    expect(ExpiringCard.new(expiration: nil).valid?).must_equal true
    expect(ExpiringCard.new(expiration: '').valid?).must_equal true
  end
end
