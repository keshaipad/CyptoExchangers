//
//  ViewController.swift
//  CryptoExchangers
//
//  Created by macbook pro on 14.07.17.
//  Copyright © 2017 Qottie. All rights reserved.
//

import Cocoa
import Alamofire
import Kanna
import Regex

class ViewController: NSViewController, NSURLConnectionDelegate {

    let exchangers = ["GatehubBTC","QuadrigaCXBTC.USD","GeminiBTC","BTC.XBTC.USD","LivecoinBTC.USD","OkCoin.Intl","YoBitBTC.USD"]
    let feeExchangers = [["Symbol":"GatehubBTC","Ask":["Wire":"15","type":"$"],"Bid":["Wire":"15","type":"$"]],["Symbol":"QuadrigaCXBTC.USD","Ask":["Wire":"0","CryptoCapital":"0","type":"%","Wire2":"5"],"Bid":["Wire":"0","CryptoCapital":"0","type":"%"]]]
    
    let askssFee = [["Symbol":"GatehubBTC","$Wire":"15"],["Symbol":"BTC.XBTC.USD","$Wire":"0","$CryptoCapital":"0"]]
    let bidsFee = [["Symbol":"GatehubBTC","$Wire":"15"],["Symbol":"BTC.XBTC.USD","$Wire":"0","$CryptoCapital":"0"]]
    let additionalFee = [["Symbol":"GatehubBTC","$Wire":"10","Type":"ask"],["Symbol":"BTC.XBTC.USD","$Wire":"10","Type":"bid"]]
    
    var tableViewData = [["":""]]
    var feeClass = [exchanersFees()]
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var resultsTableView: NSTableView!
    
    @IBOutlet weak var count1: NSTextField!
    @IBOutlet weak var summText: NSTextField!
    
    
    
    
    var countInt = 15
    
    lazy var data = NSMutableData()
    var curDic = [["":1.1 as Double as AnyObject]] as [Dictionary<String,AnyObject>]
    var curLog = [["":1.1 as Double as AnyObject]] as [Dictionary<String,AnyObject>]
    var calcData = [["":1.1 as Double as AnyObject]] as [Dictionary<String,AnyObject>]
    
    @IBAction func summDollar(_ sender: Any) {
        calculatingData()
    }
    
    
    func addFees() {
        var feeses = exchanersFees()
        feeses.symbol = "GatehubBTC"
        feeses.ask1 = ["Wire","15","$"]
        feeses.bid1 = ["Wire","15","$"]
        feeClass.append(feeses)
        feeses = exchanersFees()
        feeses.symbol = "QuadrigaCXBTC.USD"
        feeses.ask1 = ["Wire","0","$"]
        feeses.ask2 = ["CryptoCapital","0","$"]
        feeses.bid1 = ["Wire","0","$"]
        feeses.bid2 = ["CryptoCapital","0","$"]
        feeClass.append(feeses)
        feeses = exchanersFees()
        feeses.symbol = "hitbtcUSD"
        feeses.ask1 = ["Swift","1","%"]
        feeses.bid1 = ["Swift","2","%"]
        feeClass.append(feeses)
        feeses = exchanersFees()

    }
    
    func allFeeAndText(symbol:String, askOrNot: Bool, fromSumm: Double) -> [[String : AnyObject]] {
        var result = [[String : AnyObject]]() //[["Text":"werwerwer","SumResult":53]]
        var getDataFromHere = [Dictionary<String, String>]()
            if askOrNot {
                getDataFromHere = askssFee
            } else {
                getDataFromHere = bidsFee
            }
        for fee in getDataFromHere {
            if fee["Symbol"] == symbol {
                var keys = Array(fee.keys)
                keys = keys.filter { $0 != "Symbol" }
                    for key in keys {
                        var keyText = key
                        keyText.remove(at: keyText.startIndex)
                        var val = fee[key]!
                        var sumRes = 1.1
                        var textRes = ""
                        if key.characters.first! == "$" {
                            sumRes = fromSumm - Double(val)!
                            textRes = "\(keyText) -> \(fromSumm)-\(val)$=\(sumRes)"
                        } else {
                            sumRes = Double(val)! * fromSumm / 100
                            textRes = "\(keyText) -> \(fromSumm)-\(val)%=\(sumRes)"
                        }
                        for eachFee in additionalFee {
                            var askOrBid = ""
                            if askOrNot { askOrBid = "ask" } else { askOrBid = "bid" }
                            if eachFee["Symbol"] == symbol && eachFee["Type"] == askOrBid {
                                guard eachFee[key] == nil else {
                                    sumRes -= Double(eachFee[key]!)!
                                    textRes += "-\(eachFee[key]!)$=\(sumRes)"
                                    break
                                }
                            }
                        }
                        result.append(["Text":textRes as AnyObject,"SumResult":sumRes as AnyObject])

                    }
            }
        }
        return result
    }
    
    func checkForAdditionalFee(symbol:String) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addFees()
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateData), userInfo: nil, repeats: true)
        
        self.tableView.delegate = self as? NSTableViewDelegate
        self.tableView.dataSource = self
        self.resultsTableView.delegate = self as? NSTableViewDelegate
        self.resultsTableView.dataSource = self
        self.scrapeNYCMetalScene()
        getDataFromBitcoincharts()
        // Do any additional setup after loading the view.
    }
    
    func calculatingData() {
        var balance = Double(summText.stringValue)!
        //print(curDic)
        curLog.removeAll()
        for me in curDic {
            //print("me - ",me)
            var ask = me["Ask"]?.doubleValue
            var bid = me["Bid"]?.doubleValue
            for we in curDic {
                //print("we - ",we)
                if we["Symbol"] as! String != me["Symbol"] as! String {
                    var ask2 = we["Ask"]?.doubleValue
                    var bid2 = we["Bid"]?.doubleValue
                    var calculatingData = bid2! - ask!
                    var dataInProcent = Int(calculatingData * 100 / ask!)
                    
                    let methodsAsk = allFeeAndText(symbol: "\(me["Symbol"]!)", askOrNot: true, fromSumm: balance)
                    //print(methodsAsk)
                    for eachMethodAsk in methodsAsk {
                        let weHaveUSD = eachMethodAsk["SumResult"]!.doubleValue
                        let boughtBTC = Double(round(100*(weHaveUSD! / ask!))/100)
                        //print("bought ",boughtBTC,"BTC")
                        let sellBTC = Double(round(100*(boughtBTC * bid2!))/100)
                        //print("sell ",sellBTC,"$")
                        let methodsBid = allFeeAndText(symbol: "\(we["Symbol"]!)", askOrNot: false, fromSumm: sellBTC)
                            for eachMethodBid in methodsBid {
                                let inDollar = Int(eachMethodBid["SumResult"]!.doubleValue - balance)
                                let inProcentDouble = (eachMethodBid["SumResult"]!.doubleValue - balance) * 100 / balance
                                let inProcent = Double(round(100*inProcentDouble)/100)
                                print(eachMethodAsk["Text"]!," -> ",boughtBTC,"BTC"," -> ",sellBTC,"$", "-> ",eachMethodBid["Text"]!)
                                curLog.append(["Log":"\(me["Symbol"]!) \(eachMethodAsk["Text"]!) -> \(boughtBTC) BTC - > \(sellBTC) $ -> \(we["Symbol"]!) \(eachMethodBid["Text"]!)" as AnyObject,"Procent":inProcent as AnyObject,"Dollar":inDollar as AnyObject])
                            }
                        
                    }
                    
                       /* if dataInProcent > -100 {
                            
                                for i in feeClass {
                                    if i.symbol == me["Symbol"] as! String {
                                        //print(i.ask1.first!," ", me["Symbol"] as! String, " -> ",we["Symbol"] as! String," ", dataInProcent,"%")
                                        if i.ask1[2] == "$" {
                                            let n = i.ask1[1]
                                            balance -= Double(n)!
                                            for ii in feeClass {
                                                if ii.symbol == we["Symbol"] as! String {
                                                    if i.bid1[2] == "$" {
                                                        let nn = ii.bid1[1]
                                                    }
                                                }
                                            }
                                            print(i.ask1.first!,"-",i.ask1[1],i.ask1[2],"=",balance, me["Symbol"] as! String, " -> ",we["Symbol"] as! String," ", dataInProcent,"%")
                                            balance = Double(summText.stringValue)!
                                        } else {
                                            
                                        }
                                    }
                                }
                        } */
                }
            }
        }
        resultsTableView.reloadData()
    }

    
    func calcComissions(symbol: String, askOrNot: Bool, summ: Double) -> Dictionary<String, Double> {
        var result = [String():Double()]
        var summFromText = Double(summText.stringValue)
        if summ != 0 {summFromText = summ}
        for fee in feeExchangers {
            if fee["Symbol"] as! String == symbol {
                var allFees = [String():String()]
                
                
                    if askOrNot {
                        allFees = fee["Ask"] as! Dictionary<String, String>
                    } else {
                        allFees = fee["Bid"] as! Dictionary<String, String>
                    }
                
                if allFees["type"] == "$" {
                    for eachfee in allFees {
                        if eachfee.key != "type" {
                            result[eachfee.key] = Double(eachfee.value)
                        }
                    }
                } else {
                    for eachfee in allFees {
                        if eachfee.key != "type" {
                            let procent = Double(eachfee.value)
                            let res = summFromText! * procent! / 100
                            result[eachfee.key] = res
                        }
                    }
                }
            }
        }
        return result
    }
    
    func getDataFromClass() {
        
    }

    func getDataFromBitcoincharts() {
        curDic.removeAll()
        Alamofire.request("https://api.bitcoincharts.com/v1/markets.json").responseJSON { response in
            
            if let json = response.result.value as? [Dictionary<String,AnyObject>]{
                for aDic in json{
                    //print(aDic)//print each of the dictionaries
                    if let symbol = aDic["symbol"] as? AnyObject{
                        if var bid = aDic["bid"] as? AnyObject {
                            if var ask = aDic["ask"] as? AnyObject {
                                self.checkCurrency(cur: symbol, bid: bid, ask: ask)
                            }
                        }
                        
                    }
            }
                
                self.tableView.reloadData()
        }
    }
    }
    
    func checkCurrency(cur: AnyObject, bid: AnyObject, ask: AnyObject) {
        let tsymbol = "Symbol"
        let tbid = "Bid"
        let task = "Ask"
        let symbol = cur as! String
        
        switch symbol {
        case "coinbaseUSD":
            curDic.append([tsymbol:cur, tbid:bid, task:ask])
        case "hitbtcUSD":
            curDic.append([tsymbol:cur, tbid:bid, task:ask])
        case "btceUSD":
            curDic.append([tsymbol:cur, tbid:bid, task:ask])
        case "coinsbankUSD":
            curDic.append([tsymbol:cur, tbid:bid, task:ask])
        case "itbitUSD":
            curDic.append([tsymbol:cur, tbid:bid, task:ask])
        case "krakenUSD":
            curDic.append([tsymbol:cur, tbid:bid, task:ask])
        case "bitstampUSD":
            curDic.append([tsymbol:cur, tbid:bid, task:ask])
        case "cexUSD":
            curDic.append([tsymbol:cur, tbid:bid, task:ask])
        case "btccUSD":
            curDic.append([tsymbol:cur, tbid:bid, task:ask])
        default: break
        }
    }
    
    func scrapeNYCMetalScene() -> Void {
        Alamofire.request("http://coinmarketcap.com/currencies/bitcoin/#USD").responseString { response in
            //print("\(response.result.isSuccess)")
            if let html = response.result.value {
                self.parseHTML(html: html)
            }
        }
    }
    
    func parseHTML(html: String) -> Void {
        if let doc = Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
            
            // Search for nodes by CSS selector
            for show in doc.css("tr") {
                //"tr[class^='text']"
                // Strip the string of surrounding whitespace.
                let showString = show.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                filterPriceData(data: showString)
                
                //print(showString)
                // All text involving shows on this page currently start with the weekday.
                // Weekday formatting is inconsistent, but the first three letters are always there.
                //let regex = try! NSRegularExpression(pattern: "^(2|tue|wed|thu|fri|sat|sun)", options: [.caseInsensitive])
                
                //if regex.firstMatch(in: showString, options: [], range: NSMakeRange(0, showString.characters.count)) != nil {
                    //show.append(showString)
                    //print("\(showString)\n")
                }
            }
        }
    func filterPriceData(data: String) {
        for ex in exchangers {
        let digits = ex.r?.findFirst(in: data)
        if digits?.source != nil {
            let p = digits!.source
            var price = "(\\d*.)\\s*(.*)\\s*(.*)\\s*(.*)".r?.findFirst(in: p)?.group(at: 4)
            price!.remove(at: price!.startIndex)
            var dPrice = Double(price!)!
            addToDic(name: ex, price: dPrice as AnyObject)
            }
        }
    }
    
    func addToDic(name: String, price: AnyObject) {
        curDic.append(["Symbol":name as AnyObject,"Ask":price ,"Bid":price])
        self.tableView.reloadData()
    }
    
    func updateData() {
        if countInt > 1 {
            countInt-=1
            count1.stringValue = "\(countInt)"
        } else {
            countInt = 20
            calculatingData()
            //getDataFromBitcoincharts()
            //self.scrapeNYCMetalScene()
        }
    }
    
    }


    
    extension ViewController:NSTableViewDataSource{
        func numberOfRows(in tableView: NSTableView) -> Int {
            var result = 0
            if tableView == self.tableView {
                result = curDic.count
            } else if tableView == self.resultsTableView {
                result = curLog.count
            }
            return result
        }
        
        func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
            if tableView == self.tableView {
                return curDic[row][(tableColumn?.identifier)!]
            } else if tableView == self.resultsTableView {
                return curLog[row][(tableColumn?.identifier)!]
            }
             return nil
        }
    }

class exchanersFees {
    var symbol = ""
    var ask1 = [String]()
    var ask2 = [String]()
    var ask3 = [String]()
    var ask4 = [String]()
    var ask5 = [String]()
    var bid1 = [String]()
    var bid2 = [String]()
    var bid3 = [String]()
    var bid4 = [String]()
    var bid5 = [String]()
    //var bid = ["Wire","15","%","Aldd","5"] будет значить 15% + 5$
}
