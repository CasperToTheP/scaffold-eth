pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import "./SnakerMaker.sol";

import "hardhat/console.sol";

//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract YourCollectible is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {
  constructor() ERC721("SNAKES", "SNKS") {}


  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  uint256 public constant MAX_SUPPLY = 2000;
  uint256 public constant PRICE = 0.015 ether;

  struct Snake {
    Color color;
    Color bg_color;
    Color bg_color_2;
    uint256[2] bg_x;
    uint256[2] bg_y;
    string path1;
    string path2;
    uint256 bgIdx;
    uint256 thickIdx;
    uint256 thickness;
    uint256 head;
    uint256 head_mark;
    Color head_mark_color;
    uint256 snakiness_s;
    uint256 snakiness_d;
    uint256 skin_pattern_scale;
    string skin_pattern_freq;
    uint256 skin_pattern_octaves;
  }

  struct Color {
      uint256 hue;
      uint256 saturation;
      uint256 lightness;
  }

  struct Rands {
    uint256[4] x;
    uint256[4] y;
  }
  

  function mintItem(uint256 numTokens)
      public
      payable
      virtual
  {
      require(PRICE * numTokens == msg.value, "amount wrong");
      _mintItem(numTokens);
  }

      function _mintItem(uint256 numTokens) private {
        console.log("totalsuplly %s", totalSupply());
        require(totalSupply() < MAX_SUPPLY, "sold out");
        require(totalSupply() + numTokens <= MAX_SUPPLY, "Too many");
        require(numTokens > 0, "Negative");

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 id = _tokenIds.current();
            _safeMint(_msgSender(), id);
            _tokenIds.increment();
        }
    }

    function ownerMint(uint256 numTokens) public onlyOwner {
        _mintItem(numTokens);
    }

    function withdrawAll() public payable nonReentrant onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "id does not exist");
      SnakerMaker.Snake memory snk;
      string memory svg;

      string[3] memory backgroundNames = [
            "WATER",
            "DESERT",
            "SPACE"
        ];

      string[5] memory thicknessNames = [
            "SKINNY",
            "WHIMSY",
            "BASIC",
            "NOICE", 
            "THICC"
        ];

      string memory name = string(abi.encodePacked('Snake on a chain #',id.toString()));
      string memory description = string(abi.encodePacked('Every snake follows its own path (in life)'));
      (snk, svg) = SnakerMaker.generateSVGofTokenById(id);
      string memory image = Base64.encode(bytes(svg));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "attributes": [{"trait_type": "Color", "value": "',
                              SnakerMaker.toHSLString(snk.color),
                              '"},{"trait_type": "Background", "value": "',
                              backgroundNames[snk.bgIdx],
                              '"},{"trait_type": "Thickness", "value": "',
                              thicknessNames[snk.thickIdx],
                              '"}], "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

}
