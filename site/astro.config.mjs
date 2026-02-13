// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
	site: 'https://patrykquantumnomad.github.io',
	base: '/networking-tools',
	integrations: [
		starlight({
			title: 'Networking & Pentesting Tools',
			description: 'Penetration testing and network diagnostics learning lab with 17 tools, task-focused scripts, and Docker-based vulnerable targets',
			logo: {
				src: './src/assets/logo-dark.svg',
				alt: 'Networking Tools',
			},
			favicon: '/favicon.ico',
			customCss: ['./src/styles/custom.css'],
			components: {
				Footer: './src/components/Footer.astro',
				Head: './src/components/Head.astro',
			},
			head: [
				// Force dark theme
				{
					tag: 'script',
					content: `localStorage.setItem('starlight-theme', 'dark'); document.documentElement.setAttribute('data-theme', 'dark');`,
				},
				// JSON-LD: SoftwareApplication schema
				{
					tag: 'script',
					attrs: { type: 'application/ld+json' },
					content: JSON.stringify({
						'@context': 'https://schema.org',
						'@type': 'SoftwareApplication',
						name: 'Networking & Pentesting Tools',
						description: 'Penetration testing and network diagnostics learning lab with 17 tools, task-focused scripts, and Docker-based vulnerable targets',
						applicationCategory: 'DeveloperApplication',
						operatingSystem: 'Linux, macOS',
						url: 'https://patrykquantumnomad.github.io/networking-tools/',
						license: 'https://opensource.org/licenses/MIT',
						isAccessibleForFree: true,
						author: {
							'@type': 'Person',
							'@id': 'https://patrykgolabek.dev/#person',
							name: 'Patryk Golabek',
							url: 'https://patrykgolabek.dev',
						},
						offers: {
							'@type': 'Offer',
							price: '0',
							priceCurrency: 'USD',
						},
						codeRepository: 'https://github.com/PatrykQuantumNomad/networking-tools',
					}),
				},
				// Favicons
				{
					tag: 'link',
					attrs: { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/networking-tools/favicon-32x32.png' },
				},
				{
					tag: 'link',
					attrs: { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/networking-tools/favicon-16x16.png' },
				},
				{
					tag: 'link',
					attrs: { rel: 'apple-touch-icon', sizes: '180x180', href: '/networking-tools/apple-touch-icon.png' },
				},
				{
					tag: 'link',
					attrs: { rel: 'manifest', href: '/networking-tools/site.webmanifest' },
				},
				// Robots
				{
					tag: 'meta',
					attrs: { name: 'robots', content: 'index, follow' },
				},
				// OG image (site-wide)
				{
					tag: 'meta',
					attrs: { property: 'og:image', content: 'https://patrykquantumnomad.github.io/networking-tools/og-image.png' },
				},
				{
					tag: 'meta',
					attrs: { property: 'og:image:width', content: '1200' },
				},
				{
					tag: 'meta',
					attrs: { property: 'og:image:height', content: '630' },
				},
				{
					tag: 'meta',
					attrs: { property: 'og:image:alt', content: 'Networking & Pentesting Tools — 17 security tools with task scripts and Docker lab' },
				},
				// Twitter
				{
					tag: 'meta',
					attrs: { name: 'twitter:creator', content: '@PatrykGolabek' },
				},
				// Author meta
				{
					tag: 'meta',
					attrs: { name: 'author', content: 'Patryk Golabek' },
				},
			],
			social: [
				{
					icon: 'github',
					label: 'GitHub',
					href: 'https://github.com/PatrykQuantumNomad/networking-tools',
				},
			],
			sidebar: [
				{
					label: 'Tools',
					autogenerate: { directory: 'tools' },
				},
				{
					label: 'Guides',
					autogenerate: { directory: 'guides' },
				},
				{
					label: 'Diagnostics',
					autogenerate: { directory: 'diagnostics' },
				},
				{
					label: 'About the Author',
					link: 'https://patrykgolabek.dev/about/',
					attrs: { target: '_blank', rel: 'noopener' },
				},
			],
		}),
	],
});
