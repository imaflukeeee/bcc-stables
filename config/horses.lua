Config = Config or {}

Horses = { -- Gold to Dollar Ratio Based on 1899 Gold Price / sellPrice is 60% of cashPrice / Cash Price is Regular Game Price
    {
        breed = 'Mangy',
        colors = {
            -- Only Players with Specified Job will See that Horse to Purchase in the Menu
            ['A_C_Horse_MP_Mangy_Backup']           = { color = 'Mangy Coat',      cashPrice = 500,   invLimit = 10, job = {} }, -- Job Example: {'police', 'doctor'}
        }
    },
    {
        breed = 'Morgan',
        colors = {
            ['a_c_horse_morgan_bay']                = { color = 'Bay',             cashPrice = 2500,  invLimit = 20, job = {} },
            ['a_c_horse_morgan_bayroan']            = { color = 'Bay Roan',        cashPrice = 2500,  invLimit = 20, job = {} },
            ['a_c_horse_morgan_flaxenchestnut']     = { color = 'Flaxen Chestnut', cashPrice = 2500,  goldPrice = 10, invLimit = 20, job = {} },
            ['a_c_horse_morgan_palomino']           = { color = 'Palomino',        itemPrice = {name='water', amount=1, label='Horse Token'}, invLimit = 20, job = {} },
            ['a_c_horse_morgan_liverchestnut_pc']   = { color = 'Liver Chestnut',  cashPrice = 2500,  invLimit = 20, job = {} },
        }
    },
    {
        breed = 'American Paint',
        colors = {
            ['a_c_horse_americanpaint_greyovero']     = { color = 'Grey Overo',      cashPrice = 10000, invLimit = 50, job = {} },
            ['a_c_horse_americanpaint_overo']         = { color = 'Overo',           cashPrice = 10000, invLimit = 50, job = {} },
            ['a_c_horse_americanpaint_splashedwhite'] = { color = 'Splashed White',  cashPrice = 10000, invLimit = 50, job = {} },
            ['a_c_horse_americanpaint_tobiano']       = { color = 'Tobiano',         cashPrice = 10000, invLimit = 50, job = {} },
        }
    },
    {
        breed = 'Tennessee Walker',
        colors = {
            ['a_c_horse_tennesseewalker_blackrabicano']   = { color = 'Black Rabicano',  cashPrice = 60,  invLimit = 70, job = {} },
            ['a_c_horse_tennesseewalker_chestnut']        = { color = 'Chestnut',        cashPrice = 60,  invLimit = 70, job = {} },
            ['a_c_horse_tennesseewalker_dapplebay']       = { color = 'Dapple Bay',      cashPrice = 60,  invLimit = 70, job = {} },
            ['a_c_horse_tennesseewalker_flaxenroan']      = { color = 'Flaxen Roan',     cashPrice = 150, invLimit = 70, job = {} },
            ['a_c_horse_tennesseewalker_goldpalomino_pc'] = { color = 'Gold Palomino',   cashPrice = 60,  invLimit = 70, job = {} },
            ['a_c_horse_tennesseewalker_mahoganybay']     = { color = 'Mahogany Bay',    cashPrice = 60,  invLimit = 70, job = {} },
            ['a_c_horse_tennesseewalker_redroan']         = { color = 'Red Roan',        cashPrice = 60,  invLimit = 70, job = {} },
        }
    }
}