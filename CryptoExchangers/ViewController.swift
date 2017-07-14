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

class ViewController: NSViewController, NSURLConnectionDelegate {
    
    var tableViewData = [["":""]]
    
    @IBOutlet weak var tableView: NSTableView!
    lazy var data = NSMutableData()
    var curDic = [["":1.1 as Double as AnyObject]] as [Dictionary<String,AnyObject>]
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    }
    
    extension ViewController:NSTableViewDataSource{
        func numberOfRows(in tableView: NSTableView) -> Int {
            return curDic.count
        }
        
        func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
            return curDic[row][(tableColumn?.identifier)!]
        }
    }
