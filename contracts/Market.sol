//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Market {
    address owner;        // コントラクトオーナーのアドレス 
    uint public numItems; // 商品数
    bool public stopped;  // trueの場合Circuit Breakerが発動し，全てのコントラクトが使用不可能になる

     // コントラクトの呼び出しがコントラクトのオーナーか確認
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Circuit Breaker
    modifier isStopped {
        require(!stopped);
        _;
    }
     // Circuit Breakerを発動，停止する関数
    function toggleCircuit(bool _stopped) public onlyOwner {
        stopped = _stopped;
    }

    // コントラクトの呼び出しがアカウント情報登録済みユーザーか確認
    modifier onlyUser {
        require(accounts[msg.sender].resistered);
        _;
    }

    struct account {
        string  name;          // 名前
        string  email;         // emailアドレス
        bool resistered;      // アカウント未登録:false, 登録済み:true
        uint numSell;          // 出品した商品の数
        uint numBuy;           // 購入した商品の数
    }
    mapping(address => account) public accounts;

    // 各ユーザーが出品した商品の番号を記録する配列
    mapping(address => uint[]) public sellItems;

    // 各ユーザーが購入した商品の番号を記録する配列
    mapping(address => uint[]) public buyItems;

    // アカウント情報を登録する関数
    function registerAccount(string memory _name, string memory _email) public isStopped {
        require(!accounts[msg.sender].resistered); // 未登録のethアドレスか確認

        accounts[msg.sender].name = _name;   // 名前
        accounts[msg.sender].email = _email; // emailアドレス
        accounts[msg.sender].resistered = true;
    }

    // アカウント情報を修正する関数
    function modifyAccount(string memory _name, string memory _email) public onlyUser isStopped {
        accounts[msg.sender].name = _name;   // 名前
        accounts[msg.sender].email = _email; // emailアドレス
    }

    struct item {
        address sellerAddr;  // 出品者のethアドレス
        address buyerAddr;   // 購入者のethアドレス
        string seller;       // 出品者名
        string name;         // 商品名
        string description;  // 商品説明
        uint price;          // 価格
        bool payment;        // false:未支払い, true:支払済み
        bool receivement;    // false:未受取り, true:受取済み
        bool stopSell;       // false:出品中, true:出品取消し
    }
    mapping(uint => item) public items;

    // 出品する関数
    function sell(string calldata _name, string calldata _description, uint _price) public onlyUser isStopped {
        items[numItems].sellerAddr = msg.sender;            // 出品者のethアドレス
        items[numItems].seller = accounts[msg.sender].name; // 出品者名
        items[numItems].name = _name;                       // 商品名
        items[numItems].description = _description;         // 商品説明
        items[numItems].price = _price;                     // 商品価格
        accounts[msg.sender].numSell++;                     // 出品した商品数の更新
        sellItems[msg.sender].push(numItems);               // 各ユーザーが購入した商品の番号を記録
        numItems++;
    }

    // 出品内容を変更する関数
    function modifyItem(uint _numItems, string calldata _name, string calldata _description, uint _price) public onlyUser isStopped {
        require(items[_numItems].sellerAddr == msg.sender);  // コントラクトの呼び出しが出品者か確認
        require(!items[_numItems].payment);                  // 購入されていない商品か確認
        require(!items[_numItems].stopSell);                 // 出品中の商品か確認
        items[_numItems].seller = accounts[msg.sender].name; // 出品者名
        items[_numItems].name = _name;                       // 商品名
        items[_numItems].description = _description;         // 商品説明
        items[_numItems].price = _price;                     // 商品価格
    }

    // 出品を取り消す関数（出品者）
    function sellerStop(uint _numItems) public onlyUser isStopped {
        require(items[_numItems].sellerAddr == msg.sender); // コントラクトの呼び出しが出品者か確認
        require(_numItems < numItems);                      // 存在する商品か確認
        require(!items[_numItems].stopSell);                // 出品中の商品か確認
        require(!items[_numItems].payment);                 // 購入されていない商品か確認

        items[_numItems].stopSell = true; // 出品の取消し
    }

    // 出品を取り消す関数（オーナー）
    function ownerStop(uint _numItems) public onlyOwner isStopped {
        require(items[_numItems].sellerAddr == msg.sender); // コントラクトの呼び出しが出品者か確認
        require(_numItems < numItems);                      // 存在する商品か確認
        require(!items[_numItems].stopSell);                // 出品中の商品か確認
        require(!items[_numItems].payment);                 // 購入されていない商品か確認

        items[_numItems].stopSell = true;
    }

    // 購入する関数
    function buy(uint _numItems) public payable onlyUser isStopped {
        require(_numItems < numItems);                // 存在する商品か確認
        require(!items[_numItems].payment);           // 商品が売り切れていないか確認
        require(!items[_numItems].stopSell);          // 出品取消しになっていないか確認
        require(items[_numItems].price == msg.value); // 入金金額が商品価格と一致しているか確認

        items[_numItems].buyerAddr = msg.sender; // 購入者のethアドレス
        items[_numItems].payment = true;         // 支払済みにする
        items[_numItems].stopSell = true;        // 売れたので出品をストップする
        accounts[msg.sender].numBuy++;           // 購入した商品数の更新
        buyItems[msg.sender].push(_numItems);    // 各ユーザーが購入した商品の番号を記録
    }

    // 自分が出品した商品の番号を配列で取得する関数
    function itemsByOwner(address _owner) external view returns(uint[] memory) {
    uint[] memory result = new uint[](accounts[_owner].numSell);
    uint counter = 0;
    for (uint i = 0; i < numItems; i++) {
      if (items[i].sellerAddr == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
    }
}