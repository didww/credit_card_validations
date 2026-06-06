require_relative 'test_helper'

describe 'Legacy brand auto-require shim' do
  let(:detector_class) { CreditCardValidations::Detector }
  let(:flags)          { detector_class.class_variable_get(:@@legacy_autoloaded) }

  it 'declares the 7 brands moved out of brands.yaml as legacy' do
    expect(detector_class::LEGACY_PLUGIN_BRANDS).must_equal(
      %i[mir rupay elo dankort hipercard solo switch]
    )
  end

  it 'auto-loads the plugin on first reference of a removed brand' do
    flags.delete(:mir)
    detector_class.delete_brand(:mir)
    expect(detector_class.brands).wont_include :mir

    _, err = capture_io { detector_class.new('2200123412341234').valid?(:mir) }

    expect(err).must_match(/:mir was moved to a plugin/)
    expect(detector_class.brands).must_include :mir
  end

  it 'emits the deprecation warning at most once per brand per process' do
    flags.delete(:rupay)
    detector_class.delete_brand(:rupay)

    _, err = capture_io do
      3.times { detector_class.new('6061123412341234').valid?(:rupay) }
    end

    expect(err.scan(/:rupay was moved/).size).must_equal 1
  end

  it 'does not auto-restore after the shim has fired once' do
    flags.delete(:elo)
    detector_class.delete_brand(:elo)
    capture_io { detector_class.new('4011784138509070').valid?(:elo) }
    expect(detector_class.brands).must_include :elo

    detector_class.delete_brand(:elo)
    _, err = capture_io { detector_class.new('4011784138509070').valid?(:elo) }
    expect(err).must_be_empty
    expect(detector_class.brands).wont_include :elo
  ensure
    CreditCardValidations.reload!
  end

  it 'does not auto-restore after explicit require + delete_brand' do
    # An explicit plugin load runs add_brand which sets the flag via the
    # registry hook. The shim must stay out from then on.
    flags.delete(:dankort)
    load 'credit_card_validations/plugins/dankort.rb'
    expect(flags[:dankort]).must_equal true
    detector_class.delete_brand(:dankort)

    _, err = capture_io { detector_class.new('5019123412341234').valid?(:dankort) }
    expect(err).must_be_empty
    expect(detector_class.brands).wont_include :dankort
  ensure
    CreditCardValidations.reload!
  end

  it 'does nothing for brands outside LEGACY_PLUGIN_BRANDS' do
    detector_class.delete_brand(:visa)

    _, err = capture_io { detector_class.new('4111111111111111').valid?(:visa) }

    expect(err).must_be_empty
    expect(detector_class.brands).wont_include :visa
  ensure
    CreditCardValidations.reload!
  end
end
