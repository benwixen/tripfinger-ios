//
//  GuideController.swift
//  Tripfinger
//
//  Created by Preben Ludviksen on 08/10/15.
//  Copyright (c) 2015 Preben Ludviksen. All rights reserved.
//

class GuideController: UITableViewController {
    struct TableViewCellIdentifiers {
        static let guideItemCell = "GuideItemCell"
        static let categoryCell = "CategoryCell"
        static let textChildCell = "TextChild"
        static let loadingCell = "LoadingCell"
    }
    
    var currentItem: GuideItem?
    var guideSections = [GuideText]()
    var currentCategoryDescriptions = [GuideText]()
    var contentService: ContentService!
    var guideItemExpanded = false
    var guideITemCreatedAsExpanded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentItem = currentItem {
            title = currentItem.name
        }
        else {
            title = ""
        }
        
        UINib.registerNib(TableViewCellIdentifiers.guideItemCell, forTableView: tableView)
        UINib.registerNib(TableViewCellIdentifiers.categoryCell, forTableView: tableView)
        UINib.registerNib(TableViewCellIdentifiers.textChildCell, forTableView: tableView)
        UINib.registerNib(TableViewCellIdentifiers.loadingCell, forTableView: tableView)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        
        if let currentItem = currentItem {
            if currentItem is Region {
                loadRegionWithID(currentItem.id)
            }
            else if currentItem is GuideText {
                loadGuideTextWithId(currentItem.id)
            }
        }
        else {
            contentService.getRegions() {
                regions in self.loadRegionWithID(regions[0].id)
            }
        }
    }
    
    func loadRegionWithID(regionId: Int) {
        contentService.getRegionWithId(regionId) {
            region in
            
            self.currentItem = region
            self.title = region.name
            self.guideSections = region.guideSections
            println("guideSections for region: \(self.guideSections.count)")
            self.tableView.reloadData()
        }
    }
    
    func loadGuideTextWithId(guideTextId: Int) {
        contentService.getGuideTextWithId(guideTextId) {
            guideText in
            
            self.currentItem = guideText
            self.guideSections = guideText.guideSections
            println("guideSections for section: \(self.guideSections.count)")
            self.tableView.reloadData()
        }
    }
    
//    func showGuideSect() {
//        contentService.getGuideTextsForGuideItem(currentItem!) {
//            guideTexts in
//            
//            self.currentTexts = guideTexts
//            self.tableView.reloadData()
//        }
//    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && !guideItemExpanded {
            return 1
        }
        else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 && !guideItemExpanded {
            return 1
        }
        else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }
}

// MARK: - Table data source
extension GuideController: UITableViewDataSource {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return guideItemExpanded ? guideSections.count : 0;
        case 2:
            return (currentItem is GuideText) ? 0 : 2
        case 3:
            return (currentItem is GuideText) ? 0 : Attraction.Category.allValues.count - 2
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            if let currentItem = currentItem {
                println("fetching cell")
                let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.guideItemCell, forIndexPath: indexPath) as! GuideItemCell
                println("fetched cell")
                cell.setContent(currentItem)
                cell.delegate = self
                if (guideItemExpanded) {
                    cell.expand()
                }
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath: indexPath) as! UITableViewCell
                let indicator = cell.viewWithTag(1000) as! UIActivityIndicatorView
                indicator.startAnimating()
                return cell
            }
        }
        else if indexPath.section == 1 && guideItemExpanded {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.categoryCell, forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = guideSections[indexPath.row].name
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.categoryCell, forIndexPath: indexPath) as! UITableViewCell
            let index: Int
            if indexPath.section == 2 {
                index = indexPath.row
            }
            else {
                index = indexPath.row + 2
            }
            cell.textLabel?.text = Attraction.Category.allValues[index].entityName
            return cell
        }
    }
    
}

extension GuideController: GuideItemContainerDelegate {
    
    func readMoreClicked() {
        tableView.beginUpdates()
        tableView.endUpdates()
        
        guideItemExpanded = true
        tableView.reloadData()
    }
}

// MARK: - Navigation
extension GuideController {
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 && guideItemExpanded {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("guideController") as! GuideController
            vc.currentItem = guideSections[indexPath.row]
            vc.guideItemExpanded = true
            vc.contentService = contentService
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.section == 2 {
            self.tabBarController?.selectedIndex = 1
        }
        else if indexPath.section == 3 {
            if indexPath.row == 0 { // Transportation
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("guideController") as! GuideController
                let guideText = GuideText()
                
                vc.currentItem = guideSections[indexPath.row]
                vc.guideItemExpanded = true
                vc.contentService = contentService
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
