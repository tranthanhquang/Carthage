//
//  Formatting.swift
//  Carthage
//
//  Created by J.D. Healy on 1/29/15.
//  Copyright (c) 2015 Carthage. All rights reserved.
//

import Commandant
import Foundation
import LlamaKit
import PrettyColors

/// Wraps a string with terminal colors and formatting or passes it through, depending on `colorful`.
private func wrap(colorful: Bool)(wrap: Color.Wrap)(string: String) -> String {
	return colorful ? wrap.wrap(string) : string
}

/// Information about the possible parent terminal.
internal struct Terminal {
	/// Terminal type retrieved from `TERM` environment variable.
	static var terminalType: String? {
		return getEnvironmentVariable("TERM").value()
	}
	
	/// Whether terminal type is `dumb`.
	static var isDumb: Bool {
		return terminalType?.caseInsensitiveCompare("dumb") == NSComparisonResult.OrderedSame ?? false
	}
	
	/// Whether STDOUT is a TTY.
	static var isTTY: Bool {
		return isatty(STDOUT_FILENO) != 0
	}
}

public enum ColorArgument: String, ArgumentType, Printable {
	case Auto = "auto"
	case Never = "never"
	case Always = "always"
	
	/// Whether to color and format.
	public var isColorful: Bool {
		switch self {
		case .Always:
			return true
		case .Never:
			return false
		case .Auto:
			return Terminal.isTTY && !Terminal.isDumb
		}
	}
	
	public var description: String {
		return self.rawValue
	}
	
	public static let name = "color"
	
	public static func fromString(string: String) -> ColorArgument? {
		return self(rawValue: string.lowercaseString)
	}
	
}

public struct ColorOptions: OptionsType {
	let argument: ColorArgument
	let formatting: Formatting
	
	struct Formatting {
		let colorful: Bool
		
		/// Wraps a string with terminal colors and formatting or passes it through.
		typealias Wrap = (string: String) -> String
		
		init(_ colorful: Bool) {
			self.colorful = colorful
			bulletin    = wrap(colorful)(wrap: Color.Wrap(foreground: .Blue, style: .Bold))
			bullets     = self.bulletin(string: "***") + " "
			URL         = wrap(colorful)(wrap: Color.Wrap(styles: .Underlined))
			projectName = wrap(colorful)(wrap: Color.Wrap(styles: .Bold))
			path        = wrap(colorful)(wrap: Color.Wrap(foreground: .Yellow))
		}
		
		let bulletin: Wrap
		let bullets: String

		/// Wraps a string in bullets, one space of padding, and formatting.
		func bulletinTitle(string: String) -> String {
			return bulletin(string: "*** " + string + " ***")
		}
		
		let URL: Wrap
		let projectName: Wrap
		let path: Wrap
		
		/// Wraps a string in quotation marks and formatting.
		func quote(string: String, quotationMark: String = "\"") -> String {
			return wrap(colorful)(wrap: Color.Wrap(foreground: .Green))(string: quotationMark + string + quotationMark)
		}
	}
	
	static func create(argument: ColorArgument) -> ColorOptions {
		return self(argument: argument, formatting: Formatting(argument.isColorful))
	}
	
	public static func evaluate(m: CommandMode) -> Result<ColorOptions> {
		return create
			<*> m <| Option(key: "color", defaultValue: ColorArgument.Auto, usage: "apply Terminal colors and formatting — ‘auto’ || ‘always’ || ‘never’")
	}
}
