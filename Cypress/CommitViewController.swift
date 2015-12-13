//
//  UICommitViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/21/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit
import RxSwift
import RxCocoa

class CommitViewController: CypressMasterViewController, UITableViewDelegate {
    
    let disposeBag = DisposeBag()
    
    //TODO: hook up
    @IBOutlet var tableView: UITableView!
    
    let unstagedFiles = Variable<[ChangedFileViewModel]>([])
    let stagedFiles = Variable<[ChangedFileViewModel]>([])
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, ChangedFileViewModel>>()
    
    typealias Section = SectionModel<String, ChangedFileViewModel>

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if activeRepositoryStream.value == nil {
            performSegueWithIdentifier("showRepositoryListSegue", sender: nil)
        }
        
        let allFiles = combineLatest(unstagedFiles, stagedFiles) {
            (unstagedFiles: [ChangedFileViewModel], stagedFiles: [ChangedFileViewModel]) throws -> [Section] in
            return [
                SectionModel(model: "Unstaged", items: unstagedFiles),
                SectionModel(model: "Staged", items: stagedFiles)
            ]
        }
        
        dataSource.cellFactory = {
            (tableView, indexPath, file) in
            guard let cell = tableView.dequeueReusableCellWithIdentifier("changedFileCell") else {
                errorStream.value = NSError(domain: "Could not deuqueue cell with identifier \("changedFileCell")", code: 0, userInfo: nil)
                return UITableViewCell()
            }
            guard let textLabel = cell.textLabel else {
                errorStream.value = NSError(domain: "Could not get text label for cell in FileBrowserTableViewController", code: 0, userInfo: nil)
                return UITableViewCell()
            }
            textLabel.text = file.fileName
            return cell
        }
        
        dataSource.titleForHeaderInSection = {
            [unowned dataSource] sectionIndex in
            return dataSource.sectionAtIndex(sectionIndex).model
        }
        
        // Update changed files when repository stream changes
        activeRepositoryStream.subscribeNext() {
            [unowned self] in
            do {
                guard let repoURLPath = $0?.path else {
                    return
                }
                let repo = try GCRepository(existingLocalRepository: repoURLPath)
                guard let files = self.loadChangedFiles(repo) else {
                    return
                }
                (self.unstagedFiles.value, self.stagedFiles.value) = files
            }
            catch let e as NSError {
                errorStream.value = e
            }
        }
        .addDisposableTo(disposeBag)
        
        // reactive data source
        allFiles
            .bindTo(tableView.rx_itemsWithDataSource(dataSource))
            .addDisposableTo(disposeBag)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        if let files = loadChangedFiles(try! GCRepository(existingLocalRepository: activeRepositoryStream.value!.path!)) {
            (unstagedFiles.value, stagedFiles.value) = files
        }
        super.viewWillAppear(animated)
    }
    
    func loadChangedFiles(repository: GCRepository) -> (unstagedFiles: [ChangedFileViewModel], stagedFiles: [ChangedFileViewModel])? {
        var unstaged: [ChangedFileViewModel] = []
        var staged: [ChangedFileViewModel] = []
        guard let activeRepo = activeRepositoryStream.value, activeRepoPath = activeRepo.path else {
            errorStream.value = NSError(domain: "Commit view: no active repository", code: 0, userInfo: nil)
            return nil
        }
        do {
            let repo = try GCRepository(existingLocalRepository: activeRepoPath)
            let diff = try repo.diffWorkingDirectoryWithHEAD(nil, options: GCDiffOptions.IncludeUntracked, maxInterHunkLines: 0, maxContextLines: 3)
            
            guard let deltas = diff.deltas as? [GCDiffDelta] else {
                throw NSError(domain: "could not get list of deltas", code: 0, userInfo: nil)
            }
            
            for delta in deltas {
                var isBinary = ObjCBool(false)
                let patch = try repo.makePatchForDiffDelta(delta, isBinary: &isBinary)
                let file = delta.oldFile.path
                unstaged.append(ChangedFileViewModel(patch: patch, fileURL: NSURL(fileURLWithPath: file)))
            }
        }
        catch let e as NSError {
            errorStream.value = e
        }
        return (unstaged, staged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
