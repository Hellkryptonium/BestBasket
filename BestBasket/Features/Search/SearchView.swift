import SwiftUI

struct SearchView: View {
    @Bindable var model: SearchViewModel; let openProduct:(CatalogProduct)->Void; let showFilters:()->Void
    @FocusState private var focused: Bool
    var body: some View {
        let results = model.searchResults()
        let suggestions = model.suggestions(for: model.query)
        return NavigationStack { VStack(spacing:0) {
        HStack(spacing:10) { Image(systemName:"magnifyingglass").foregroundStyle(AppPalette.muted); TextField("Product, brand, or keyword",text:$model.query).focused($focused).submitLabel(.search).onSubmit { model.recordSearch(model.query); focused = false }; if !model.query.isEmpty { Button { model.query="" } label:{ Image(systemName:"xmark.circle.fill").foregroundStyle(AppPalette.muted) }.accessibilityLabel("Clear search") } }
            .padding(13).background(.white,in:RoundedRectangle(cornerRadius:15)).padding(.horizontal,16).padding(.top,8)
        if model.query.isEmpty && model.activeFilterCount == 0 { suggestionsSection }
        else {
            if !model.query.isEmpty && !suggestions.isEmpty {
                ScrollView(.horizontal,showsIndicators:false) { HStack(spacing:8) { ForEach(suggestions) { product in Button(product.name) { model.query=product.name; model.recordSearch(product.name); focused=false }.font(.caption.weight(.semibold)).foregroundStyle(AppPalette.ink).padding(.horizontal,11).padding(.vertical,8).background(.white,in:Capsule()) } }.padding(.horizontal,16).padding(.top,10) }
            }
            HStack { Text("\(results.count) sample results").font(.caption.weight(.semibold)).foregroundStyle(AppPalette.muted); Spacer(); Menu { ForEach(ProductSort.allCases) { sort in Button(sort.rawValue) { model.sort=sort } } } label: { Label(model.sort.rawValue,systemImage:"arrow.up.arrow.down").font(.caption.weight(.semibold)).foregroundStyle(AppPalette.ink) }; Button(action:showFilters) { Label("Filter\(model.activeFilterCount > 0 ? " · \(model.activeFilterCount)" : "")",systemImage:"slider.horizontal.3").font(.caption.weight(.semibold)).foregroundStyle(AppPalette.cobalt) } }
                .padding(.horizontal,16).padding(.vertical,12)
            if model.activeFilterCount > 0 { ScrollView(.horizontal,showsIndicators:false) { HStack { if let category=model.selectedCategory { FilterPill(title:category) { model.selectedCategory=nil } }; if let brand=model.selectedBrand { FilterPill(title:brand) { model.selectedBrand=nil } }; if let platform=model.selectedPlatform { FilterPill(title:platform) { model.selectedPlatform=nil } }; if let maximumPrice=model.maximumPrice { FilterPill(title:"Up to \(money(maximumPrice))") { model.maximumPrice=nil } }; if model.minimumRating > 0 { FilterPill(title:String(format:"%.1f+ stars",model.minimumRating)) { model.minimumRating=0 } }; if model.inStockOnly { FilterPill(title:"In stock") { model.inStockOnly=false } }; Button("Reset") { model.resetFilters() }.font(.caption.weight(.semibold)) }.padding(.horizontal,16) }.padding(.bottom,6) }
            if results.isEmpty { ContentUnavailableView("No matches",systemImage:"magnifyingglass",description:Text("Try another term or reset your filters.")); Spacer() }
            else { ScrollView { LazyVStack(spacing:11) { ForEach(results) { product in SearchResultRow(product:product,model:model) { openProduct(product) } } }.padding(.horizontal,16).padding(.bottom,20) }.scrollDismissesKeyboard(.interactively) }
        }
    }.background(AppPalette.oat).appScreen("Search") } }
    private var suggestionsSection: some View { ScrollView { VStack(alignment:.leading,spacing:22) {
        if !model.recentSearches.isEmpty { VStack(alignment:.leading,spacing:12) { SectionTitle(title:"Recent searches"); ForEach(model.recentSearches,id:\.self) { term in Button { model.query=term; model.recordSearch(term) } label:{ Label(term,systemImage:"clock.arrow.circlepath").font(.subheadline).foregroundStyle(AppPalette.ink).frame(maxWidth:.infinity,alignment:.leading) } } } }
        VStack(alignment:.leading,spacing:12) { SectionTitle(title:"Popular searches"); LazyVGrid(columns:[GridItem(.adaptive(minimum:110),alignment:.leading)],alignment:.leading,spacing:9) { ForEach(["Amul milk","oats","Tata salt","coffee"],id:\.self) { term in Button(term) { model.query=term; model.recordSearch(term) }.font(.caption.weight(.semibold)).foregroundStyle(AppPalette.ink).padding(.horizontal,12).padding(.vertical,9).background(.white,in:Capsule()) } } }
        VStack(alignment:.leading,spacing:12) { SectionTitle(title:"Browse categories"); ForEach(model.categories,id:\.self) { category in Button { model.selectedCategory=category } label:{ HStack { Text(category).foregroundStyle(AppPalette.ink); Spacer(); Image(systemName:"chevron.right").foregroundStyle(AppPalette.muted) }.padding(14).background(.white,in:RoundedRectangle(cornerRadius:14)) } } }
        Text("Illustrative mock catalogue · prices are sample data").font(.caption2).foregroundStyle(AppPalette.muted)
    }.padding(16) } }
}
