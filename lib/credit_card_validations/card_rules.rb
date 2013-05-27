module CreditCardValidations
  module CardRules
    ########  most used brands #########


    VISA = [
        {length: [16], prefixes: ['4']}
    ]
    MASTERCARD = [
        {length: [16], prefixes: ['51', '52', '53', '54', '55']}
    ]
    ######## other brands ########
    AMEX = [
        {length: [15], prefixes: ['34', '37']}
    ]

    DINERS = [
        {length: [14], prefixes: ['300', '301', '302', '303', '304', '305', '36']},
    ]

    #There are Diners Club (North America) cards that begin with 5. These are a joint venture between Diners Club and MasterCard, and are processed like a MasterCard
    DINERS_US = [
        {length: [16], prefixes: ['54', '55']}
    ]

    DISCOVER = [
        {length: [16], prefixes: ['6011', '622126', '622127', '622128', '622129', '62213',
                                '62214', '62215', '62216', '62217', '62218', '62219',
                                '6222', '6223', '6224', '6225', '6226', '6227', '6228',
                                '62290', '62291', '622920', '622921', '622922', '622923',
                                '622924', '622925', '644', '645', '646', '647', '648',
                                '649', '65']}
    ]

    JCB = [
        {length: [16], prefixes: ['3528', '3529', '353', '354', '355', '356', '357', '358']}
    ]


    LASER = [
        {length: [16, 17, 18, 19], prefixes: ['6304', '6706', '6771', '6709']}
    ]

    MAESTRO = [
        {length: [12, 13, 14, 15, 16, 17, 18, 19], prefixes: ['5018', '5020', '5038', '6304', '6759', '6761', '6762','6763', '6764', '6765', '6766']}
    ]

    SOLO = [
        {length: [16, 18, 19], prefixes: ['6334', '6767']}
    ]

    UNIONPAY = [
        {length: [16, 17, 18, 19], prefixes: ['620', '621', '623', '625', '626'], skip_validation: true}
    ]

    DANKROT = [
       {length: [16], prefixes: ['5019']}
    ]


  end
end
