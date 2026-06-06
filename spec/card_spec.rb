require_relative 'test_helper'

describe CreditCardValidations::Card do
  Card = CreditCardValidations::Card
  let(:future) { Date.today >> 12 }
  let(:visa)   { VALID_NUMBERS[:visa].first }
  let(:amex)   { VALID_NUMBERS[:amex].first }

  it 'is valid with a good PAN, future expiration, matching CVV' do
    card = Card.new(
      number: visa,
      month: future.month, year: future.year,
      verification_value: '123', name: 'John Smith'
    )
    expect(card.valid?).must_equal true
    expect(card.brand).must_equal :visa
    expect(card.last_digits).must_equal visa.tr(' -', '')[-4, 4]
  end

  it 'detects amex and requires a 4-digit CID' do
    card = Card.new(number: amex, month: future.month, year: future.year, verification_value: '123')
    expect(card.brand).must_equal :amex
    expect(card.valid?).must_equal false
    expect(card.errors[:verification_value]).wont_be_empty
  end

  it 'rejects an expired card' do
    past = Date.today << 24
    card = Card.new(number: visa, month: past.month, year: past.year, verification_value: '123')
    expect(card.expired?).must_equal true
    expect(card.valid?).must_equal false
  end

  it 'rejects an invalid PAN' do
    card = Card.new(number: '4111111111111110', month: future.month, year: future.year, verification_value: '123')
    expect(card.valid?).must_equal false
    expect(card.errors[:number]).wont_be_empty
  end

  it 'exposes display_number and masked accessor' do
    card = Card.new(number: visa, month: future.month, year: future.year, verification_value: '123')
    digits = visa.tr(' -', '')
    expect(card.display_number).must_equal "#{'*' * (digits.length - 4)}#{digits[-4, 4]}"
  end

  it 'formats the PAN per brand convention' do
    card = Card.new(number: amex, month: future.month, year: future.year, verification_value: '1234')
    digits = amex.tr(' -', '')
    expect(card.formatted_number).must_equal "#{digits[0,4]} #{digits[4,6]} #{digits[10,5]}"
  end
end
