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

    let exchangers = ["GatehubBTC","QuadrigaCXBTC.USD","GeminiBTC","BTC.XBTC.USD","LivecoinBTC.USD","OkCoin.Intl","YoBitBTC.USD","Exmo","BX.Thailand"]
    
    let askssFee = [["Symbol":"GatehubBTC","$Wire":"15"],["Symbol":"hitbtcUSD","%Swift":"1"],["Symbol":"coinsbankUSD","$Wire":"0","%Okpay":"0.5"],["Symbol":"coinbaseUSD","$Wire":"10"],["Symbol":"GeminiBTC","$Wire":"0"],["Symbol":"BTC.XBTC.USD","$Wire":"0","$CryptoCapital":"0"],["Symbol":"itbitUSD","$Swift":"40"],["Symbol":"btccUSD","$CryptoCapital":"0"],["Symbol":"krakenUSD","$Wire":"10"],["Symbol":"YoBitBTC.USD","$Capitalist":"0","$Okpay":"0","$PerfectMoney":"0"],["Symbol":"BTC-X","%Wire":"1","$Cash Kharckov":"0"],["Symbol":"LivecoinBTC.USD","%Perfectmoney":"1.5","$Wire":"50","%BTC-у USD":"2.5","$Capitalist":"0"],["Symbol":"bitstampUSD","$Wire":"10"],["Symbol":"OkCoin.Intl","%Wire":"0.1"],["Symbol":"Exmo","$Wire":"20","$Capitalist":"0","$CryptoCapital":"0","%AdvCash":"3","%Perfect Money":"3"],["Symbol":"cexUSD","$Wire":"0","$CryptoCapital":"0","%Visa":"3.5"],["Symbol":"BX.Thailand","$CashBangkok":"0"]]
    let bidsFee = [["Symbol":"GatehubBTC","$Wire":"15"],["Symbol":"hitbtcUSD","$Wire":"0","$CryptoCapital":"0"],["Symbol":"BTC.XBTC.USD","$Swift":"35"],["Symbol":"coinsbankUSD","%Wire":"1","%Okpay":"1.5"],["Symbol":"coinbaseUSD","$Wire":"25"],["Symbol":"GeminiBTC","$Wire":"0"],["Symbol":"BTC.XBTC.USD","$Wire":"0","$CryptoCapital":"0"],["Symbol":"itbitUSD","$Swift":"40"],["Symbol":"btccUSD","%CryptoCapital":"0.2"],["Symbol":"krakenUSD","$Wire":"10"],["Symbol":"YoBitBTC.USD","%PerfectMoney":"3","%Okpay":"3","%Capitalist":"5"],["Symbol":"BTC","$Wire":"0.5","$Cash Kharckov":"0"],["Symbol":"LivecoinBTC.USD","%Perfectmoney":"0.5","%Wire":"1.5","$Capitalist":"0"],["Symbol":"bitstampUSD","%Wire":"0.1"],["Symbol":"OkCoin.Intl","%Wire":"0.1"],["Symbol":"Exmo","$Wire":"20","$CryptoCapital":"0","$AdvCash":"0","%Perfect Money":"0.5","%Visa":"3"],["Symbol":"cexUSD","$Visa":"3.8","$Wire":"50","%CryptoCapital":"1"],["Symbol":"BX.Thailand","%CashBangkok":"0.1"]]
    
    let additionalFee = [["Symbol":"LivecoinBTC.USD","%Wire":"9","Type":"bid"],["Symbol":"Exmo","%Visa":"7.5","Type":"bid"],["Symbol":"cexUSD","$Visa":"0.25","Type":"ask"]]
    
    var tableViewData = [["":""]]
    
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
                            sumRes = fromSumm - (Double(val)! * fromSumm / 100)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //_ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateData), userInfo: nil, repeats: true)
        
        
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
                                if inDollar > 1 {
                                 let inProcentDouble = (eachMethodBid["SumResult"]!.doubleValue - balance) * 100 / balance
                                 let inProcent = Double(round(100*inProcentDouble)/100)
                                 print(eachMethodAsk["Text"]!," -> ",boughtBTC,"BTC"," -> ",sellBTC,"$", "-> ",eachMethodBid["Text"]!)
                                 curLog.append(["Log":"\(me["Symbol"]!) \(eachMethodAsk["Text"]!) -> \(boughtBTC) BTC - > \(sellBTC) $ -> \(we["Symbol"]!) \(eachMethodBid["Text"]!)" as AnyObject,"Procent":inProcent as AnyObject,"Dollar":inDollar as AnyObject])
                                }
                            }
                        
                    }
                }
            }
        }
        resultsTableView.reloadData()
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
        //case "btccUSD":
            //curDic.append([tsymbol:cur, tbid:bid, task:ask])
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
            getDataFromBitcoincharts()
            self.scrapeNYCMetalScene()
            calculatingData()
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
        func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
            resultsTableView.reloadData()
        }
    }
