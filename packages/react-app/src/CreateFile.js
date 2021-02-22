import React, { useState, useRef, useEffect } from "react";
import { useHistory } from "react-router-dom";
import "antd/dist/antd.css";
import "./App.css";
import {
  UndoOutlined,
  ClearOutlined,
  PlaySquareOutlined,
  HighlightOutlined,
  BgColorsOutlined,
  BorderOutlined,
} from "@ant-design/icons";
import {
  Row,
  Button,
  Input,
  InputNumber,
  Form,
  message,
  Col,
  Slider,
  Space,
} from "antd";
import { useLocalStorage } from "./hooks";
import { addToIPFS, transactionHandler } from "./helpers";
import CanvasDraw from "react-canvas-draw";
import {
  SketchPicker,
  CirclePicker,
  TwitterPicker,
  AlphaPicker,
} from "react-color";
import LZ from "lz-string";
import { useAtom } from "jotai";
import { Uploader } from "./components";
import { fileAtom } from "./hooks/Uploader";

const Hash = require("ipfs-only-hash");
const pickers = [CirclePicker, TwitterPicker, SketchPicker];

export default function CreateFile(props) {
  let history = useHistory();
  const [sending, setSending] = useState(false);
  const [name, setName] = useState("");
  const [number, setNumber] = useState(0);
  const [file] = useAtom(fileAtom);

  const mintInk = async (inkUrl, jsonUrl, limit) => {
    let contractName = "NiftyInk";
    let regularFunction = "createInk";
    let regularFunctionArgs = [
      inkUrl,
      jsonUrl,
      props.ink.attributes[0]["value"],
    ];
    let signatureFunction = "createInkFromSignature";
    let signatureFunctionArgs = [
      inkUrl,
      jsonUrl,
      props.ink.attributes[0]["value"],
      props.address,
    ];
    let getSignatureTypes = [
      "bytes",
      "bytes",
      "address",
      "address",
      "string",
      "string",
      "uint256",
    ];
    let getSignatureArgs = [
      "0x19",
      "0x0",
      props.readKovanContracts["NiftyInk"].address,
      props.address,
      inkUrl,
      jsonUrl,
      limit,
    ];

    let createInkConfig = {
      ...props.transactionConfig,
      contractName,
      regularFunction,
      regularFunctionArgs,
      signatureFunction,
      signatureFunctionArgs,
      getSignatureTypes,
      getSignatureArgs,
    };

    console.log(createInkConfig);

    let result = await transactionHandler(createInkConfig);

    return result;
  };

  const createInk = async (values) => {
    console.log("Success:", values);

    setSending(true);

    let imageData; //= drawingCanvas.current.canvas.drawing.toDataURL("image/png");

    let decompressed = LZ.decompress(props.drawing);
    let compressedArray = LZ.compressToUint8Array(decompressed);

    let drawingBuffer = Buffer.from(compressedArray);
    let imageBuffer = Buffer.from(imageData.split(",")[1], "base64");

    let currentInk = props.ink;

    currentInk["attributes"] = [
      {
        trait_type: "Limit",
        value: values.limit.toString(),
      },
    ];
    currentInk["name"] = values.title;
    let newEns;
    try {
      newEns = await props.mainnetProvider.lookupAddress(props.address);
    } catch (e) {
      console.log(e);
    }
    const timeInMs = new Date();
    const addressForDescription = !newEns ? props.address : newEns;
    currentInk["description"] =
      "A Nifty Ink by " +
      addressForDescription +
      " on " +
      timeInMs.toUTCString();

    props.setIpfsHash();

    const drawingHash = await Hash.of(drawingBuffer);
    console.log("drawingHash", drawingHash);
    const imageHash = await Hash.of(imageBuffer);
    console.log("imageHash", imageHash);

    currentInk["drawing"] = drawingHash;
    currentInk["image"] = "https://ipfs.io/ipfs/" + imageHash;
    currentInk["external_url"] = "https://nifty.ink/" + drawingHash;
    props.setInk(currentInk);
    console.log("Ink:", props.ink);

    var inkStr = JSON.stringify(props.ink);
    const inkBuffer = Buffer.from(inkStr);

    const jsonHash = await Hash.of(inkBuffer);
    console.log("jsonHash", jsonHash);

    try {
      var mintResult = await mintInk(
        drawingHash,
        jsonHash,
        values.limit.toString()
      );
    } catch (e) {
      console.log(e);
      setSending(false);
    }

    if (mintResult) {
      const drawingResult = addToIPFS(drawingBuffer, props.ipfsConfig);
      const imageResult = addToIPFS(imageBuffer, props.ipfsConfig);
      const inkResult = addToIPFS(inkBuffer, props.ipfsConfig);

      const drawingResultInfura = addToIPFS(
        drawingBuffer,
        props.ipfsConfigInfura
      );
      const imageResultInfura = addToIPFS(imageBuffer, props.ipfsConfigInfura);
      const inkResultInfura = addToIPFS(inkBuffer, props.ipfsConfigInfura);

      Promise.all([drawingResult, imageResult, inkResult]).then((values) => {
        console.log("FINISHED UPLOADING TO PINNER", values);
        message.destroy();
      });

      setSending(false);
      props.setViewDrawing(LZ.decompress(props.drawing));
      // setDrawingSize(10000);
      props.setDrawing("");
      history.push("/ink/" + drawingHash);

      Promise.all([
        drawingResultInfura,
        imageResultInfura,
        inkResultInfura,
      ]).then((values) => {
        console.log("INFURA FINISHED UPLOADING!", values);
      });
    }
  };

  const onFinishFailed = (errorInfo) => {
    console.log("errorInfo:", errorInfo);
  };

  const top = (
    <div>
      <Form
        layout={"inline"}
        name="createFile"
        onFinish={createInk}
        onFinishFailed={onFinishFailed}
        labelAlign={"middle"}
        style={{ justifyContent: "center", marginBottom: "30px" }}
      >
        <Form.Item
          name="title"
          rules={[
            { required: true, message: "What is this work of art called?" },
          ]}
        >
          <Input
            onChange={(e) => setName(e.target.value)}
            placeholder={"name"}
            style={{ fontSize: 16 }}
          />
        </Form.Item>

        <Form.Item
          name="limit"
          rules={[{ required: true, message: "How many files can be minted?" }]}
        >
          <InputNumber
            onChange={(e) => {
              setNumber(e);
            }}
            placeholder={"limit"}
            style={{ fontSize: 16 }}
            min={0}
            precision={0}
          />
        </Form.Item>

        <Form.Item>
          <Button
            loading={sending}
            type="primary"
            htmlType="submit"
            disabled={!name || !number || !file}
          >
            Upload
          </Button>
        </Form.Item>
      </Form>
    </div>
  );

  return (
    <div
      style={{
        textAlign: "center",
        maxWidth: "600px",
        margin: "0 auto",
      }}
    >
      {top}
      <Uploader />
    </div>
  );
}