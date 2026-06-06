require_relative 'test_helper'

class PaymentForm
  include ActiveModel::Model
  attr_accessor :number, :cvv, :other_cvv

  validates :cvv,       credit_card_cvv: { brand_from: :number }, allow_blank: true
  validates :other_cvv, credit_card_cvv: { brand: :amex },        allow_blank: true
end

describe ActiveModel::Validations::CreditCardCvvValidator do
  let(:amex_pan) { VALID_NUMBERS[:amex].first }
  let(:visa_pan) { VALID_NUMBERS[:visa].first }

  describe ':brand_from option' do
    it 'requires 4 digits when the linked number is amex' do
      form = PaymentForm.new(number: amex_pan, cvv: '1234')
      expect(form.valid?).must_equal true

      form.cvv = '123'
      expect(form.valid?).must_equal false
      expect(form.errors[:cvv]).wont_be_empty
    end

    it 'requires 3 digits when the linked number is visa' do
      form = PaymentForm.new(number: visa_pan, cvv: '123')
      expect(form.valid?).must_equal true

      form.cvv = '1234'
      expect(form.valid?).must_equal false
    end

    it 'rejects non-digit input' do
      form = PaymentForm.new(number: visa_pan, cvv: 'abc')
      expect(form.valid?).must_equal false
    end
  end

  describe ':brand option (literal)' do
    it 'requires 4 digits when brand is :amex' do
      form = PaymentForm.new(other_cvv: '1234')
      expect(form.valid?).must_equal true

      form.other_cvv = '123'
      expect(form.valid?).must_equal false
    end
  end
end
