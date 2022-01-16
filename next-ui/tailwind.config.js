const { colors } = require('tailwindcss/defaultTheme');
// const colors = require('tailwindcss/colors')

module.exports = {
	content: [
		"./pages/**/*.{js,ts,jsx,tsx}",
		"./components/**/*.{js,ts,jsx,tsx}"],
	darkMode: false, // or 'media' or 'class'
	theme: {
		fontFamily: {
			'serif': ["KohSantepheap", 'serif'],
			'sans': ['"Open Sans"', "roboto", 'Helvetica', 'Arial', 'ui-sans-serif',],
			'body': ['"Open Sans"'],
			'display': ['Oswald'],
		},
		extend: {
			backgroundImage: {
				"dark-water": "url('/images/header-bg.jpg')",
				"misty-forest": "url('/images/evgeni-evgeniev-LPKk3wtkC-g-unsplash.jpg')"
			},
			fontSize: {
				'2xs': '.65rem'
			},
		},
	},
	variants: {
		extend: {},
	},
	plugins: [
		require('@tailwindcss/forms'),
	],
};
