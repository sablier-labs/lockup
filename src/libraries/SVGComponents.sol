// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Strings } from "@openzeppelin/utils/Strings.sol";

// solhint-disable max-line-length
library SVGComponents {
    using Strings for uint256;

    string internal constant BACKGROUND =
        '<rect width="100%" height="100%" filter="url(#noise)" /> <use href="#light" x="0" y="0" fill-opacity="0.9" /> <use href="#light" x="1000" y="1000" fill-opacity="0.9" /> <rect x="70" y="70" width="860" height="860" rx="45" ry="45" fill="white" fill-opacity="0.03" stroke="white" stroke-opacity="0.1" stroke-width="4"/> <path d="M 200,450 a 300,300 0 1,1 600,0 a 300,300 0 1,1 -600,0" fill="white" fill-opacity="0.02" stroke="url(#fillOutline)" stroke-opacity="1" stroke-width="4"/> <use href="#logo" x="170" y="170" transform="scale(0.6)" /> <path id="boxOutline" fill="none" d="M125 45h750s80 0 80 80v750s0 80 -80 80h-750s-80 0 -80 -80v-750s0 -80 80 -80" />';

    string internal constant COLOR_BACKGROUND = "#161822";

    string internal constant LIGHT =
        '<g id="light"> <circle cx="0" cy="0" r="500" fill="url(#fillLight)" gradientUnits="userSpaceOnUse" /> </g>';

    string internal constant LOGO =
        '<g id="logo" fill="white" fill-opacity="0.1"> <path d="m133.559,124.034c-.013,2.412-1.059,4.848-2.923,6.402-2.558,1.819-5.168,3.439-7.888,4.996-14.44,8.262-31.047,12.565-47.674,12.569-8.858.036-17.838-1.272-26.328-3.663-9.806-2.766-19.087-7.113-27.562-12.778-13.842-8.025,9.468-28.606,16.153-35.265h0c2.035-1.838,4.252-3.546,6.463-5.224h0c6.429-5.655,16.218-2.835,20.358,4.17,4.143,5.057,8.816,9.649,13.92,13.734h.037c5.736,6.461,15.357-2.253,9.38-8.48,0,0-3.515-3.515-3.515-3.515-11.49-11.478-52.656-52.664-64.837-64.837l.049-.037c-1.725-1.606-2.719-3.847-2.751-6.204h0c-.046-2.375,1.062-4.582,2.726-6.229h0l.185-.148h0c.099-.062,.222-.148,.37-.259h0c2.06-1.362,3.951-2.621,6.044-3.842C57.763-3.473,97.76-2.341,128.637,18.332c16.671,9.946-26.344,54.813-38.651,40.199-6.299-6.096-18.063-17.743-19.668-18.811-6.016-4.047-13.061,4.776-7.752,9.751l68.254,68.371c1.724,1.601,2.714,3.84,2.738,6.192Z" /> </g>';

    enum BoxType {
        DURATION,
        PROGRESS,
        STATUS,
        STREAMED
    }

    struct BoxVars {
        bool isProgress;
        string label;
        uint256 labelLength;
        uint256 textLength;
        uint256 words;
        uint256 progressCircleLeftOffset;
        uint256 boxWidth;
        string progressCircle;
        string element;
    }

    function box(
        BoxType boxType,
        string memory colorAccent,
        string memory text,
        uint256 progress
    )
        internal
        pure
        returns (string memory, uint256)
    {
        BoxVars memory vars;
        vars.isProgress = boxType == BoxType.PROGRESS;

        vars.label = boxTypeToString(boxType);
        vars.labelLength = getTextLength(vars.label, true);
        vars.textLength = getTextLength(text, false);

        vars.words = vars.textLength > vars.labelLength ? vars.textLength : vars.labelLength;

        vars.progressCircleLeftOffset = vars.words + 45;
        vars.boxWidth = vars.isProgress ? vars.progressCircleLeftOffset + 45 : vars.progressCircleLeftOffset;

        vars.progressCircle = vars.isProgress
            ? string.concat(
                '<g> <circle cx="',
                vars.progressCircleLeftOffset.toString(),
                '" cy="50" r="22" fill="none" stroke="',
                COLOR_BACKGROUND,
                '" stroke-width="10" /> <circle transform="rotate(-95)" transform-origin="',
                vars.progressCircleLeftOffset.toString(),
                ' 50" cx="',
                vars.progressCircleLeftOffset.toString(),
                '" cy="50" r="22" fill="none" stroke="',
                colorAccent,
                '" stroke-width="5" stroke-linecap="round" stroke-dasharray="',
                ((progress * 138) / 100).toString(),
                ', 138" /> </g>'
            )
            : "";

        vars.element = string.concat(
            '<g id="',
            vars.label,
            '"> <rect height="100" width="',
            vars.boxWidth.toString(),
            '" rx="15" ry="15" fill="white" fill-opacity="0.03" stroke="white" stroke-opacity="0.1" stroke-width="4" />',
            vars.progressCircle,
            '<text x="20" y="34" fill="white" font-size="22px" lengthAdjust="spacing" font-family="\'Courier New\', \'Arial\', \'monospace\'">',
            vars.label,
            "</text>",
            '<text x="20" y="72" fill="white" font-size="26px" lengthAdjust="spacing" font-family="\'Courier New\', \'Arial\', \'monospace\'">',
            text,
            "</text></g>"
        );

        return (vars.element, vars.boxWidth);
    }

    function boxTypeToString(BoxType boxType) internal pure returns (string memory) {
        if (boxType == BoxType.DURATION) {
            return "Duration";
        } else if (boxType == BoxType.PROGRESS) {
            return "Progress";
        } else if (boxType == BoxType.STATUS) {
            return "Status";
        }
        return "Streamed";
    }

    function getTextLength(string memory text, bool isMini) internal pure returns (uint256 length) {
        bytes memory textBytes = bytes(text);

        for (uint256 i = 0; i < textBytes.length;) {
            if (isMini) {
                length += 15;
            } else {
                length += 16;
            }
            unchecked {
                i += 1;
            }
        }
    }

    function hourglass(bool isDepleted) internal pure returns (string memory) {
        return string.concat(
            '<g id="hourglass"> <path d="m566,161.201v-53.924c0-19.382-22.513-37.563-63.398-51.198-40.756-13.592-94.946-21.079-152.587-21.079s-111.838,7.487-152.602,21.079c-40.893,13.636-63.413,31.816-63.413,51.198v53.924c0,17.181,17.704,33.427,50.223,46.394v284.809c-32.519,12.96-50.223,29.206-50.223,46.394v53.924c0,19.382,22.52,37.563,63.413,51.198,40.763,13.592,94.954,21.079,152.602,21.079s111.831-7.487,152.587-21.079c40.886-13.636,63.398-31.816,63.398-51.198v-53.924c0-17.196-17.704-33.435-50.223-46.401V207.603c32.519-12.967,50.223-29.206,50.223-46.401Zm-347.462,57.793l130.959,131.027-130.959,131.013V218.994Zm262.924.022v262.018l-130.937-131.006,130.937-131.013Z" fill="#161822"> </path> <g> <g> <path d="m481.46,481.54v81.01c-2.35.77-4.82,1.51-7.39,2.23-30.3,8.54-74.65,13.92-124.06,13.92-53.6,0-101.24-6.33-131.47-16.16v-81l46.3-46.31h170.33l46.29,46.31Z" fill="url(#fillRight)" />',
            '<path d="m435.17,435.23c0,1.17-.46,2.32-1.33,3.44-7.11,9.08-41.93,15.98-83.81,15.98s-76.7-6.9-83.82-15.98c-.87-1.12-1.33-2.27-1.33-3.44v-.04l8.34-8.35.01-.01c13.72-6.51,42.95-11.02,76.8-11.02s62.97,4.49,76.72,11l8.42,8.42Z" fill="url(#fillLeft)" />',
            "</g>",
            isDepleted
                ? ""
                :
                '<g> <polygon points="350 350.026 415.03 284.978 285 284.978 350 350.026" fill="url(#fillRight)" /> <path d="m416.341,281.975c0,.914-.354,1.809-1.035,2.68-5.542,7.076-32.661,12.45-65.28,12.45-32.624,0-59.738-5.374-65.28-12.45-.681-.872-1.035-1.767-1.035-2.68,0-.914.354-1.808,1.035-2.676,5.542-7.076,32.656-12.45,65.28-12.45,32.619,0,59.738,5.374,65.28,12.45.681.867,1.035,1.762,1.035,2.676Z" fill="url(#fillLeft)" /> </g>',
            '</g> <g> <line x1="481.818" y1="218.142" x2="481.819" y2="562.428" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <line x1="515.415" y1="207.352" x2="515.416" y2="537.579" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <line x1="184.584" y1="206.823" x2="184.585" y2="537.579" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <line x1="218.181" y1="218.118" x2="218.181" y2="562.537" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <g> <path d="m565.641,107.28c0,9.537-5.56,18.629-15.676,26.973h-.023c-9.204,7.596-22.194,14.562-38.197,20.592-39.504,14.936-97.325,24.355-161.733,24.355-90.48,0-167.948-18.582-199.953-44.948h-.023c-10.115-8.344-15.676-17.437-15.676-26.973,0-39.735,96.554-71.921,215.652-71.921s215.629,32.185,215.629,71.921Z" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <path d="m134.36,161.203c0,39.735,96.554,71.921,215.652,71.921s215.629-32.186,215.629-71.921" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <line x1="134.36" y1="161.203" x2="134.36" y2="107.28" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <line x1="565.64" y1="161.203" x2="565.64" y2="107.28" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> </g> <g> <path d="m184.582,492.656c-31.354,12.485-50.223,28.58-50.223,46.142,0,9.536,5.564,18.627,15.677,26.969h.022c8.503,7.005,20.213,13.463,34.524,19.159,9.999,3.991,21.269,7.609,33.597,10.788,36.45,9.407,82.181,15.002,131.835,15.002s95.363-5.595,131.807-15.002c10.847-2.79,20.867-5.926,29.924-9.349,1.244-.467,2.473-.942,3.673-1.424,14.326-5.696,26.035-12.161,34.524-19.173h.022c10.114-8.342,15.677-17.433,15.677-26.969,0-17.562-18.869-33.665-50.223-46.15" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <path d="m134.36,592.72c0,39.735,96.554,71.921,215.652,71.921s215.629-32.186,215.629-71.921" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <line x1="134.36" y1="592.72" x2="134.36" y2="538.797" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <line x1="565.64" y1="592.72" x2="565.64" y2="538.797" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> </g> <polyline points="218.185 481.901 218.231 481.854 350.015 350.026 481.822 218.152" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <polyline points="481.822 481.901 481.798 481.877 481.775 481.854 350.015 350.026 218.185 218.129" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /> <path d="m184.58,537.58c0,5.45,4.27,10.65,12.03,15.42h.02c5.51,3.39,12.79,6.55,21.55,9.42,30.21,9.9,78.02,16.28,131.83,16.28,49.41,0,93.76-5.38,124.06-13.92,2.7-.76,5.29-1.54,7.75-2.35,8.77-2.87,16.05-6.04,21.56-9.43h0c7.76-4.77,12.04-9.97,12.04-15.42" fill="none" stroke="url(#fillOutline)" stroke-linecap="round" stroke-miterlimit="10" stroke-width="4" /></g> </g>'
        );
    }

    function styles(string memory colorAccent) internal pure returns (string memory) {
        return string.concat(
            '<filter id="noise">',
            '<feFlood flood-color="',
            COLOR_BACKGROUND,
            '" flood-opacity="1" x="0" y="0" width="100%" height="100%" result="floodFill" />',
            '<feTurbulence baseFrequency="0.4" numOctaves="3" stitchTiles="noStitch" type="fractalNoise" result="noise" />',
            '<feBlend in="noise" in2="floodFill" mode="soft-light" />',
            "</filter>",
            '<linearGradient id="fillOutline" gradientTransform="rotate(90)" gradientUnits="userSpaceOnUse">',
            '<stop offset="50%" stop-color="',
            colorAccent,
            '" stop-opacity="1" />',
            '<stop offset="80%" stop-color="',
            COLOR_BACKGROUND,
            '" stop-opacity="1" />',
            "</linearGradient>",
            '<linearGradient id="fillRight" x0="0" y0="0" x1="100%" y1="100%">',
            '<stop offset="10%" stop-color="',
            COLOR_BACKGROUND,
            '" stop-opacity="1" />',
            '<stop offset="100%" stop-color="',
            colorAccent,
            '" stop-opacity="1" />',
            '<animate attributeName="x1" dur="6s" values="30%;60%;120%;60%;30%;" repeatCount="indefinite" />',
            "</linearGradient>",
            '<linearGradient id="fillLeft" x0="0" y0="0" x1="0%" y1="0%">',
            '<stop offset="0%" stop-color="',
            colorAccent,
            '" stop-opacity="1" />',
            '<stop offset="100%" stop-color="',
            COLOR_BACKGROUND,
            '" stop-opacity="1" />',
            "</linearGradient>",
            '<radialGradient id="fillLight">',
            '<stop offset="0%" stop-color="',
            colorAccent,
            '" stop-opacity="0.6" />',
            '<stop offset="100%" stop-color="',
            COLOR_BACKGROUND,
            '" stop-opacity="0" />',
            "</radialGradient>"
        );
    }

    function words(string memory offset, string memory text) internal pure returns (string memory) {
        return string.concat(
            '<textPath startOffset="',
            offset,
            '" href="#boxOutline" fill="white" fill-opacity="0.8" font-size="26px" lengthAdjust="spacing" font-family="\'Courier New\', \'Arial\', \'monospace\'">',
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="50s" repeatCount="indefinite" />',
            text,
            "</textPath>"
        );
    }
}
