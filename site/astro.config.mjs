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
			customCss: ['./src/styles/custom.css'],
			components: {
				Footer: './src/components/Footer.astro',
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
				// Open Graph
				{
					tag: 'meta',
					attrs: { property: 'og:type', content: 'website' },
				},
				{
					tag: 'meta',
					attrs: { property: 'og:site_name', content: 'Networking & Pentesting Tools' },
				},
				{
					tag: 'meta',
					attrs: { property: 'og:locale', content: 'en_US' },
				},
				// Twitter card
				{
					tag: 'meta',
					attrs: { name: 'twitter:card', content: 'summary' },
				},
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
