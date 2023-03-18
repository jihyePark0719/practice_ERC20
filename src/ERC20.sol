// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    bool private isPause;
    address public owner;

    // erc-20 extension을 위한 변수
    mapping(address => uint256) nonce_list;
    bytes32 constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        

    constructor(string memory name_, string memory symbol_){
        owner = msg.sender;
        _totalSupply = 100 ether;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    // 토큰의 메타데이터들을 반환할 함수들 선언
    // 공개되어도 상관없기 때문에 public, view modifier 로 함.
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // 어떤 계좌인지 확인해야하니까 인자로 address를 받음.
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // 꼭 필요한 event 2개 선언
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // external: 컨트랙트 내부에서는 호출이 불가능함
    // public: 컨트랙트 내부에서도 호출이 가능함
    function transfer(address _to, uint256 _value) external returns (bool success) {
            // balances[msg.sender] -= _value; // 이런 식으로 하면 _value의 값이 어느정도인지 모르기 때문에 취약점 발생(Integer Underflow 발생)
            // balances[_to] += _value; // 또한 토큰을 추가하는 _to address가 zero address 인지도 검증해야 함.

            // // emit을 꼭 해야하는 이유?
            // // frontend단에서 띄워야 하기 때문?
            // // internal 
            // emit Transfer(msg.sender, _to, _value);
            require(!isPause, "pause now");
            require(_to != address(0), "transfer to the zero address");
            // require(balances[msg.sender] >= _value, "value exceeds balance");
        
            unchecked {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
            }
            emit Transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "approve to the zero address");

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns(bool success) {      
        // zero address 확인
        require(_from != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        
        // approval 여부 확인
        uint256 currenstAllowance = allowance(_from, msg.sender);
        if (currenstAllowance != type(uint256).max){
            require(currenstAllowance >= _value, "insufficient allowance");
            unchecked {
                allowances[_from][msg.sender] -= _value;
            }
        }        
        // 잔고 확인
        require(balances[_from] >= _value, "value exceeds balance");

        unchecked {
                balances[_from] -= _value;
                balances[_to] += _value;
            }

        emit Transfer(_from, _to, _value);
    }


    // mint와 burn 은 컨트랙트 내부에서만 되도록 internal로 함
    function _mint(address _owner, uint256 _value) internal {
        // zero address 확인
        require(_owner != address(0), "mint to the zero address");
        _totalSupply += _value;
        unchecked {
            balances[_owner] += _value;
        }
        // 이건 뭘까...
        emit Transfer(address(0), _owner, _value);        
    }
    function _burn(address _owner, uint256 _value) internal {
        require(_owner != address(0), "burn from the zero address");
        require(balances[_owner] >= _value, "burn amount exceeds balance");
        unchecked {
            balances[_owner] -= _value;
            _totalSupply -= _value;
        }
        emit Transfer(_owner, address(0), _value);
    }

    function pause() public{
        require(owner == msg.sender, "not owner");
        isPause = true;
    }

    function _toTypedDataHash(bytes32 data) public virtual returns (bytes32) {
        return keccak256(abi.encode(data));
    }

    function nonces(address addr) public view returns (uint) {
        return nonce_list[addr];
    }

    function _approve(address _owner, address spender, uint value) private {
        allowances[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }

    // ecrecover() 활용 : 서명 검증하는 함수
    function permit(address _owner, address spender, uint256 value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                keccak256(abi.encode(PERMIT_TYPEHASH, _owner, spender, value, nonce_list[_owner], deadline))
            )
        ); 
        nonce_list[_owner]++;
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == _owner, 'INVALID_SIGNER');
        _approve(_owner, spender, value);
    }

}