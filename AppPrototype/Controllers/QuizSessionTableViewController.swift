//
//  QuizSessionTableViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/27/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit
import BEMCheckBox

class QuizSessionTableViewController: UITableViewController, CollapsibleTableViewHeaderDelegate {
    @IBOutlet weak var timerView: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    
    var quiz: Quiz?
    private var checkBoxesGrouped: [Int: BEMCheckBoxGroup] = [:]
    
    private var countdownTimer: Timer?
    private var timerSecondsCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        let headerNib = UINib.init(nibName: "CollapsibleTableViewHeader", bundle: Bundle.main)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "CollapsibleTableViewHeader")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setTimer()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return quiz?.questions.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let question = quiz?.questions[section], !question.collapsed {
            let minRowCount = 1
            return question.answers.count + minRowCount
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let section = indexPath.section
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Question Cell", for: indexPath)
            cell.textLabel?.text = quiz?.questions[section].title
            
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Answer Cell", for: indexPath) as! QuizAnswerTableViewCell
            cell.quiz = quiz
            cell.indexPath = indexPath
            if let quiz = quiz {
                let answerText = NSMutableAttributedString(string: quiz.questions[section].answers[row - 1].text)
                let attributedText = NSMutableAttributedString(
                    string: "\(Array("abcdefghijklmnopqrstuvwxyz".characters)[row - 1])) ",
                    attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 17)]
                )
                attributedText.append(answerText)
                cell.answerLabel?.attributedText = attributedText
                
                if quiz.type == .singleChoice {
                    cell.checkBox.boxType = .circle
                    if let boxGroup = checkBoxesGrouped[section] {
                        boxGroup.addCheckBox(toGroup: cell.checkBox)
                    } else {
                        checkBoxesGrouped[section] = BEMCheckBoxGroup(checkBoxes: [cell.checkBox])
                    }
                } else {
                    cell.checkBox.boxType = .square
                }
            }
            return cell
        }

    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CollapsibleTableViewHeader") as? CollapsibleTableViewHeader ?? CollapsibleTableViewHeader(reuseIdentifier: "CollapsibleTableViewHeader")
        
        header.titleLabel.text = "Question #\(section + 1)"
        header.setCollapsed(quiz?.questions[section].collapsed ?? false)
        
        header.section = section
        header.delegate = self
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? QuizAnswerTableViewCell {
            cell.didSelectCell()
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func toggleSection(_ header: CollapsibleTableViewHeader, section: Int) {
        if var questions = quiz?.questions {
            let collapsed = !questions[section].collapsed
            
            questions[section].collapsed = collapsed
            header.setCollapsed(collapsed)
            
            tableView.reloadSections(NSIndexSet(index: section) as IndexSet, with: .automatic)
        }
    }
    
    private func setTimer() {
        if let timeLimit = quiz?.timeLimit {
            switch timeLimit {
            case .none:
                timerLabel.text = nil
            case .minutes(let minutes):
                timerSecondsCount = minutes * 60
                countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(tick(timer:)), userInfo: nil, repeats: true)
            }
        }
    }
    
    @objc private func tick(timer: Timer) {
        timerSecondsCount -= 1
        if timerSecondsCount < 0 {
            countdownTimer?.invalidate()
        } else {
            let seconds: Int = timerSecondsCount % 60
            let minutes: Int = (timerSecondsCount / 60) % 60
            let hours: Int = timerSecondsCount / 3600
            timerLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
