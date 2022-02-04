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
    
    struct account {
        string name;          // 名前
        string email;         // emailアドレス
        bool resistered;      // アカウント未登録:false, 登録済み:true
        int numSell;          // 出品した商品の数
        int numBuy;           // 購入した商品の数
    }
    mapping(address => account) public accounts;

    // 各ユーザーが出品した商品の番号を記録する配列
    mapping(address => uint[]) public sellItems;

    // 各ユーザーが購入した商品の番号を記録する配列
    mapping(address => uint[]) public buyItems;

    // 返金する際に参照するフラグ
    mapping(uint => bool) public refundFlags; // 返金すると，falseからtrueに変わる

    // アカウント情報を登録する関数
    function registerAccount(string _name, string _email) public isStopped {
        require(!accounts[msg.sender].resistered); // 未登録のethアドレスか確認

        accounts[msg.sender].name = _name;   // 名前
        accounts[msg.sender].email = _email; // emailアドレス
        accounts[msg.sender].resistered = true;
    }

    // アカウント情報を修正する関数
    function modifyAccount(string _name, string _email) public onlyUser isStopped {
        accounts[msg.sender].name = _name;   // 名前
        accounts[msg.sender].email = _email; // emailアドレス
    }
}