import UIKit
import RxSwift
import RxCocoa

let StandardTouchSize = CGFloat(44)

class SearchyView: UIView, SearchyImageTransitionable {
	private let disposeBag = DisposeBag()
    private let tableHandler:TableHandler
    private let textField = UITextField()
    
    let searchResults = Variable<SearchResults>([])
    let selectionEvents:Observable<SearchResult>
    
    var searchTerm:Observable<String>
    
    init(imageProvider: ImageProvider) {
        tableHandler = TableHandler(imageProvider: imageProvider)
        selectionEvents = tableHandler.selectionEvents
        searchTerm = textField.rx_text.debounce(0.33, scheduler: MainScheduler.instance)
        
        super.init(frame: CGRectZero)
        
        tableHandler.parent = self
        
        disposeBag ++ tableHandler.data <~ searchResults
        
        textField.placeholder = "Search..."
        textField.backgroundColor = UIColor(white: 0.925, alpha: 1.0)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .Always
        textField.clearButtonMode = .Always
        textField.returnKeyType = .Done
        textField.autocorrectionType = .No
        self.addSubview(textField)
        
        self.addSubview(tableHandler.view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setVisibleTransitionState(_:Bool) {}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let contentSize = self.bounds
        let textFieldHeight = max(textField.sizeThatFits(CGSize(width: contentSize.width, height: CGFloat.max)).height, StandardTouchSize)
        
        textField.frame = CGRect(x: 0, y: 0, width: contentSize.width, height: textFieldHeight)
        tableHandler.view.frame = CGRect(x: 0, y: textFieldHeight, width: contentSize.width, height: contentSize.height - textFieldHeight)
        
        let sizeForSquare = (self.bounds.width - 30) / 2
        tableHandler.layout.itemSize = CGSize(width: sizeForSquare, height: sizeForSquare + 20)
    }
    
    func imageRectForItem(item: SearchResult) -> CGRect {
        let rowIndex = searchResults.value.indexOf(item) ?? 0
        guard let cell = tableHandler.view.cellForItemAtIndexPath(NSIndexPath(forRow: rowIndex, inSection: 0)) as? SearchyCell else { return CGRectZero }
        
        return cell.convertRect(cell.imageRect(), toView: self)
    }
    
    func imageViewForItem(item: SearchResult) -> UIImageView? {
        let rowIndex = searchResults.value.indexOf(item) ?? 0
        guard let cell = tableHandler.view.cellForItemAtIndexPath(NSIndexPath(forRow: rowIndex, inSection: 0)) as? SearchyCell else { return nil }
        
        return cell.imageView
    }
    
    class TableHandler : UICollectionViewFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
		private let disposeBag = DisposeBag()
        weak var parent:SearchyView?
        let view:UICollectionView
        let data = Variable<SearchResults>([])
        private let imageProvider:ImageProvider
		private let selectionEventsPublisher = PublishSubject<SearchResult>()
		let selectionEvents:Observable<SearchResult>
        let layout = UICollectionViewFlowLayout()
        
        init(imageProvider: ImageProvider) {
			selectionEvents = selectionEventsPublisher.asObservable()
            self.imageProvider = imageProvider
            view = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
            
            super.init()
            
            layout.sectionInset = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
            
            view.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
            view.registerClass(SearchyCell.self, forCellWithReuseIdentifier: SearchyCell.reuseIdentifier)
            view.dataSource = self
            view.delegate = self
            view.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
            view.backgroundColor = UIColor.whiteColor()
            
            data.asObservable().subscribeNext { [unowned self] _ in
                self.view.reloadData()
            }.addDisposableTo(disposeBag)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return data.value.count
        }
        
        func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier(SearchyCell.reuseIdentifier, forIndexPath: indexPath) as? SearchyCell else {
                fatalError()
            }
            
            cell.populateCell(SearchyDisplayItem(result: data.value[indexPath.row], imageProvider: imageProvider))
            
            return cell
        }
        
        func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
            parent?.textField.resignFirstResponder()
            selectionEventsPublisher.onNext(data.value[indexPath.row])
        }
    }
}