// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
	site: 'https://patrykquantumnomad.github.io',
	base: '/networking-tools',
	integrations: [
		starlight({
			title: 'Networking Tools',
			description: 'Pentesting and network diagnostic learning lab',
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
			],
		}),
	],
});
