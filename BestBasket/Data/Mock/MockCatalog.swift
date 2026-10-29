import Foundation

enum MockCatalog {
    static let products: [CatalogProduct] = [
        .init(id:"amul-milk",name:"Taaza Milk",brand:"Amul",packSize:"1 L",category:"Dairy",systemImage:"drop.fill",rating:4.5,reviewCount:1280,description:"Fresh toned milk for everyday tea, coffee and cooking."),
        .init(id:"fortune-oil",name:"Sunflower Oil",brand:"Fortune",packSize:"1 L",category:"Pantry",systemImage:"oilcan.fill",rating:4.4,reviewCount:860,description:"Light, versatile cooking oil for everyday meals."),
        .init(id:"tata-salt",name:"Iodized Salt",brand:"Tata",packSize:"1 kg",category:"Pantry",systemImage:"cube.fill",rating:4.6,reviewCount:2400,description:"Fine iodised salt, a kitchen cupboard essential."),
        .init(id:"atta",name:"Whole Wheat Atta",brand:"Aashirvaad",packSize:"5 kg",category:"Pantry",systemImage:"bag.fill",rating:4.5,reviewCount:1900,description:"Whole wheat flour milled for soft, wholesome rotis."),
        .init(id:"bread",name:"Whole Wheat Bread",brand:"Britannia",packSize:"400 g",category:"Bakery",systemImage:"birthday.cake.fill",rating:4.2,reviewCount:520,description:"Soft whole wheat slices for breakfast and sandwiches."),
        .init(id:"juice",name:"Orange Juice",brand:"Tropicana",packSize:"1 L",category:"Beverages",systemImage:"cup.and.saucer.fill",rating:4.1,reviewCount:730,description:"A bright fruit drink served chilled."),
        .init(id:"curd",name:"Masti Dahi",brand:"Amul",packSize:"400 g",category:"Dairy",systemImage:"takeoutbag.and.cup.and.straw.fill",rating:4.4,reviewCount:640,description:"Creamy set curd for meals, snacks and marinades."),
        .init(id:"eggs",name:"Farm Fresh Eggs",brand:"Eggoz",packSize:"6 pcs",category:"Dairy",systemImage:"oval.fill",rating:4.5,reviewCount:380,description:"A half dozen farm-fresh eggs. Sample listing."),
        .init(id:"oats",name:"Rolled Oats",brand:"Quaker",packSize:"1 kg",category:"Breakfast",systemImage:"leaf.fill",rating:4.3,reviewCount:910,description:"Wholegrain oats for a quick breakfast bowl."),
        .init(id:"cornflakes",name:"Corn Flakes",brand:"Kellogg's",packSize:"475 g",category:"Breakfast",systemImage:"sun.max.fill",rating:4.2,reviewCount:770,description:"Crunchy corn flakes for an easy start to the day."),
        .init(id:"chips",name:"Classic Salted Chips",brand:"Lay's",packSize:"150 g",category:"Snacks",systemImage:"sparkles",rating:4.1,reviewCount:1100,description:"Crisp salted potato chips. Sample listing."),
        .init(id:"biscuits",name:"Good Day Cashew Cookies",brand:"Britannia",packSize:"200 g",category:"Snacks",systemImage:"cookie",rating:4.3,reviewCount:850,description:"Buttery cookies with cashew pieces."),
        .init(id:"coffee",name:"Classic Coffee",brand:"Nescafé",packSize:"100 g",category:"Beverages",systemImage:"mug.fill",rating:4.5,reviewCount:1550,description:"Instant coffee for a rich cup at home."),
        .init(id:"tea",name:"Gold Tea",brand:"Tata Tea",packSize:"500 g",category:"Beverages",systemImage:"cup.and.saucer.fill",rating:4.4,reviewCount:1220,description:"A brisk black tea blend for everyday chai."),
        .init(id:"soap",name:"Dove Cream Beauty Bar",brand:"Dove",packSize:"3 x 100 g",category:"Personal care",systemImage:"drop",rating:4.4,reviewCount:980,description:"Gentle cleansing bars with a moisturising feel."),
        .init(id:"shampoo",name:"Daily Shine Shampoo",brand:"Dove",packSize:"340 ml",category:"Personal care",systemImage:"shower.fill",rating:4.2,reviewCount:600,description:"A daily shampoo for soft, clean hair."),
        .init(id:"toothpaste",name:"Strong Teeth Toothpaste",brand:"Colgate",packSize:"200 g",category:"Personal care",systemImage:"cross.case.fill",rating:4.3,reviewCount:1300,description:"Mint toothpaste for everyday oral care."),
        .init(id:"detergent",name:"Matic Liquid Detergent",brand:"Surf Excel",packSize:"1 L",category:"Household",systemImage:"washer.fill",rating:4.4,reviewCount:720,description:"Liquid detergent for front and top load machines."),
        .init(id:"dishwash",name:"Dishwash Gel",brand:"Vim",packSize:"750 ml",category:"Household",systemImage:"sparkles",rating:4.3,reviewCount:680,description:"Citrus dishwash gel for everyday clean-up."),
        .init(id:"tissue",name:"Facial Tissues",brand:"Origami",packSize:"100 pulls",category:"Household",systemImage:"square.stack.3d.up.fill",rating:4.1,reviewCount:240,description:"Soft facial tissues for home and travel."),
        .init(id:"apples",name:"Royal Gala Apples",brand:"Fresh farm",packSize:"4 pcs",category:"Fruits",systemImage:"carrot.fill",rating:4.2,reviewCount:200,description:"Crisp apples. Fresh produce availability is illustrative."),
        .init(id:"bananas",name:"Robusta Bananas",brand:"Fresh farm",packSize:"6 pcs",category:"Fruits",systemImage:"carrot.fill",rating:4.1,reviewCount:180,description:"Sweet bananas for snacks and smoothies."),
        .init(id:"tomatoes",name:"Local Tomatoes",brand:"Fresh farm",packSize:"500 g",category:"Vegetables",systemImage:"carrot.fill",rating:4.0,reviewCount:140,description:"Ripe tomatoes for salads, curries and sauces."),
        .init(id:"onions",name:"Red Onions",brand:"Fresh farm",packSize:"1 kg",category:"Vegetables",systemImage:"carrot.fill",rating:4.0,reviewCount:160,description:"Kitchen staple for everyday cooking."),
        .init(id:"paneer",name:"Malai Paneer",brand:"Amul",packSize:"200 g",category:"Dairy",systemImage:"square.fill",rating:4.5,reviewCount:550,description:"Soft paneer for curries and quick meals."),
        .init(id:"peanut-butter",name:"Creamy Peanut Butter",brand:"Pintola",packSize:"350 g",category:"Breakfast",systemImage:"takeoutbag.and.cup.and.straw.fill",rating:4.4,reviewCount:430,description:"Creamy peanut spread for toast and smoothies.")
    ]
    static let platforms = ["Blinkit", "Zepto", "BigBasket", "Instamart"]
    static let offers: [PriceOffer] = products.flatMap { product in
        platforms.enumerated().map { index, platform in
            let base = price(for: product.id)
            let variation = Decimal((product.id.count * (index + 2)) % 9 - 3)
            let amount = max(Decimal(12), base + variation)
            let available = !(product.id == "tissue" && platform == "Zepto") && !(product.id == "apples" && platform == "Instamart")
            let discount: Decimal = (index == 1 && product.id.count % 2 == 0) ? 5 : 0
            return PriceOffer(id: "\(product.id)-\(platform)", productID: product.id, retailer: platform, price: amount, originalPrice: discount > 0 ? amount + discount : nil, discount: discount, deliveryFee: index == 0 ? 15 : (index == 2 ? 25 : 18), available: available, delivery: index == 0 ? "20–30 min" : (index == 1 ? "15–25 min" : "30–45 min"), colorName: platform)
        }
    }
    static func price(for id: String) -> Decimal {
        let values: [String: Decimal] = ["amul-milk":62,"fortune-oil":148,"tata-salt":25,"atta":285,"bread":48,"juice":110,"curd":35,"eggs":72,"oats":185,"cornflakes":165,"chips":20,"biscuits":35,"coffee":245,"tea":265,"soap":115,"shampoo":245,"toothpaste":110,"detergent":235,"dishwash":99,"tissue":75,"apples":120,"bananas":55,"tomatoes":38,"onions":42,"paneer":95,"peanut-butter":210]
        return values[id] ?? 50
    }
}

