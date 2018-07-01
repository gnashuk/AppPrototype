//
//  ViewController.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/28/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private var shapeLayer = CAShapeLayer()
    private var countDownTimer = Timer()
    private var timerValue = 900
    private var label = UILabel()
    
    var clockView = UIView() // ClockView()

    override func viewDidLoad() {
        super.viewDidLoad()
//        let clockView = ClockView()
        self.createLabel()
        clockView.backgroundColor = UIColor.white
        clockView.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        
        self.setTimer(value: 10)
        self.startClockTimer()
        
//        view.addSubview(clockView)
        navigationItem.titleView = clockView
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func addCircle() {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 160,y: 240), radius: CGFloat(100), startAngle: CGFloat(-M_PI_2), endAngle:CGFloat(2*M_PI-M_PI_2), clockwise: true)
        
        self.shapeLayer.path = circlePath.cgPath
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.strokeColor = UIColor.red.cgColor
        self.shapeLayer.lineWidth = 1.0
        
        self.clockView.layer.addSublayer(self.shapeLayer)
    }
    
    private func createLabel() {
        self.label = UILabel(frame: CGRect(x: 72, y: 220, width: 200, height: 40))
        
        self.label.font = UIFont(name: self.label.font.fontName, size: 40)
        self.label.textColor = UIColor.red
        
        self.clockView.addSubview(self.label)
    }
    
    private func startAnimation() {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = Double(self.timerValue)
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        self.shapeLayer.add(animation, forKey: "ani")
    }
    
    private func updateLabel(value: Int) {
        self.setLabelText(value: self.timeFormatted(totalSeconds: value))
        self.addCircle()
    }
    
    private func setLabelText(value: String) {
        self.label.text = value
    }
    
    private func timeFormatted(totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        let hours: Int = totalSeconds / 3600
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Needs @objc to be able to call private function in NSTimer.
    @objc private func countdown(dt: Timer) {
        self.timerValue-=1
        if self.timerValue < 0 {
            self.countDownTimer.invalidate()
        }
        else {
            self.setLabelText(value: self.timeFormatted(totalSeconds: self.timerValue))
        }
    }
    
    func setTimer(value: Int) {
        self.timerValue = value
        self.updateLabel(value: value)
    }
    
    func startClockTimer() {
        //self.countDownTimer.invalidate()
        self.countDownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(countdown(dt:)), userInfo: nil, repeats: true)
        self.startAnimation()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

