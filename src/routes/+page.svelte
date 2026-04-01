<script lang="ts">
	const apps = [
		{
			name: 'SevenDo',
			description: 'Weekly planner TO DO app — plan your seven days with clarity and focus.'
		},
		{
			name: 'Saber Investir',
			description: 'Personal finance and investment simulator with real stock market data.'
		},
		{
			name: 'DoughIt',
			description: 'Pizza dough recipe calculator with step-by-step guides for perfect results.'
		}
	];
</script>

<!-- Hero -->
<section class="flex flex-col items-center justify-center min-h-screen px-6 text-center bg-white">
	<img
		src="/stylish-engineering-logo.png"
		alt="Stylish Engineering"
		class="w-32 h-32 mb-8 object-contain"
	/>
	<h1 class="text-5xl font-bold tracking-tight text-gray-900 mb-4">Stylish Engineering</h1>
	<p class="text-xl text-gray-500 max-w-md">
		Software that works beautifully. Inspired by function, guided by taste.
	</p>
</section>

<!-- About -->
<section class="px-6 py-24 max-w-2xl mx-auto text-center">
	<h2 class="text-3xl font-bold text-gray-900 mb-6">About</h2>
	<p class="text-lg text-gray-600 leading-relaxed">
		We build tools that respect your time and intelligence. Every product is designed to be genuinely
		useful — no bloat, no noise. Like a well-engineered instrument, the interface disappears and only
		the work remains.
	</p>
</section>

<!-- Apps -->
<section class="px-6 py-24 bg-gray-50">
	<div class="max-w-4xl mx-auto">
		<h2 class="text-3xl font-bold text-gray-900 mb-12 text-center">Apps</h2>
		<div class="grid gap-6 sm:grid-cols-3">
			{#each apps as app}
				<div class="bg-white rounded-2xl p-8 shadow-sm border border-gray-100 flex flex-col gap-4">
					<div>
						<h3 class="text-xl font-semibold text-gray-900 mb-2">{app.name}</h3>
						<p class="text-gray-500 text-sm leading-relaxed">{app.description}</p>
					</div>
					<span
						class="inline-block self-start text-xs font-medium px-3 py-1 rounded-full bg-gray-100 text-gray-500"
					>
						Coming Soon
					</span>
				</div>
			{/each}
		</div>
	</div>
</section>

<!-- Footer -->
<footer class="px-6 py-12 text-center text-sm text-gray-400">
	<p>© {new Date().getFullYear()} Stylish Engineering. All rights reserved.</p>
</footer>
