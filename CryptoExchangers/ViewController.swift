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
    
    var tableViewData = [["":""]]
    
    @IBOutlet weak var tableView: NSTableView!
    lazy var data = NSMutableData()
    var curDic = [["":1.1 as Double as AnyObject]] as [Dictionary<String,AnyObject>]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrapeNYCMetalScene()
        self.tableView.delegate = self as? NSTableViewDelegate
        self.tableView.dataSource = self
        
        getDataFromBitcoincharts()
        // Do any additional setup after loading the view.
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
            print("\(response.result.isSuccess)")
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
    }


    
    extension ViewController:NSTableViewDataSource{
        func numberOfRows(in tableView: NSTableView) -> Int {
            return curDic.count
        }
        
        func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
            return curDic[row][(tableColumn?.identifier)!]
        }
    }
