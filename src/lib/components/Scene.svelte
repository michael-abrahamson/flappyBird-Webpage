<script lang="ts">
	import { T, useRender, useThrelte, useFrame, useTask } from '@threlte/core';
	import { ContactShadows, Float, Grid, OrbitControls } from '@threlte/extras';
	import {
		MeshBasicMaterial,
		PlaneGeometry,
		Raycaster,
		SphereGeometry,
		Vector2,
		Mesh,
		Color,
		Vector3,
		CylinderGeometry,
		PMREMGenerator
	} from 'three';
	import { onMount } from 'svelte';
	import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
	import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
	import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
	import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

	let planeRef; //check intersection with objects
	let sphereRef; //Bird
	let pillarRef;

	const { scene, camera, renderer } = useThrelte();
	let intersectionPoint;
	let translY = 0;
	let translAccelleration = 0;

	let angleZ = 0;
	let angleAccelleration = 0;

	let pmrem = new PMREMGenerator(renderer);
	let envMapRT;

	const composer = new EffectComposer(renderer);
	composer.setSize(innerWidth, innerHeight);

	const setupEffectComposer = () => {
		const renderPass = new RenderPass(scene, camera.current);
		composer.addPass(renderPass);

		const bloomPass = new UnrealBloomPass(new Vector2(innerWidth, innerHeight), 0.275, 1, 0);
		composer.addPass(bloomPass);

		const outputPass = new OutputPass();
		composer.addPass(outputPass);
	};

	useRender(({ scene }) => {
		if (intersectionPoint) {
			const targetY = intersectionPoint?.y || 0;
			translAccelleration += (targetY - translY) * 0.002; // stiffness
			translAccelleration *= 0.95; // damping
			translY += translAccelleration;

			const dir = intersectionPoint
				.clone()
				.sub(new Vector3(0, translY, 0))
				.normalize();
			const dirCos = dir.dot(new Vector3(0, 1, 0));
			const angle = Math.acos(dirCos) - Math.PI * 0.5;
			angleAccelleration += (angle - angleZ) * 0.01; //stiffness
			angleAccelleration *= 0.75; //damping -> without this its super reactive
			angleZ += angleAccelleration;
		}

		//Reflections/postprocessing
		// if (envMapRT) envMapRT.dispose();
		// spaceshipRef.visible = false;
		// scene.background = null;
		// envMapRT=pmrem.fromScene(scene,0, 0.1, 1000);
		// scene.background = new Color('#598889').multiplyScalar(0.05);
		// spaceshipRef.visible = true;

		// spaceshipRef.traverse((child) => {
		// 	if (child?.material?.envMapIntensity) {
		// 		child.material.envMap = envMapRT.texture;
		// 		child.material.envMapIntensity = 100;
		// 		child.material.normalScale.set(0.3, 0.3);
		// 	}
		// });

		composer.render();
	});

	const gravityAcc = -0.1;
	let yVel = 0;
	let upwardAcc = 2;
	let xAcc = 0;

	useTask((delta) => {
		yVel += gravityAcc;
		xAcc += 0.1;
	});
	onMount(() => {
		setupEffectComposer();

		/**
		 * On keyboard "space" click, an upward velocity is added to the yVel
		 * Spring motion must be added such that there is a stiffness and damping
		 * @param event
		 */
		function onclick(event) {
			yVel += upwardAcc;
			const keys = new KeyboardEvent('space');
		}
		window.addEventListener('click', onclick);
		return () => {
			window.addEventListener('Click', onclick);
		};
	});
</script>

<T.PerspectiveCamera makeDefault position.x={-5 + xAcc} position.y={6} position.z={10} fov={40}>
	<OrbitControls enableZoom={false} />
</T.PerspectiveCamera>

<T.DirectionalLight intensity={1.8} position={[0, 10, 0]} castShadow shadow.bias={-0.0001} />
<T.AmbientLight intensity={0.2} />

<Grid
	position.y={-0.001}
	cellColor="#ffffff"
	sectionColor="#ffffff"
	sectionThickness={0}
	fadeDistance={25}
	cellSize={2}
	visible={false}
/>

<T.Mesh bind:ref={planeRef} visible={false}>
	<T.PlaneGeometry args={[20, 20]} />
	<T.MeshBasicMaterial color={[1, 0, 1]} transparent opacity={0.25} />
</T.Mesh>

<T.Mesh position.x={-1 + xAcc} position.z={0} bind:ref={sphereRef} visible={true} position.y={yVel}>
	<T.SphereGeometry args={[0.1, 20, 20]} />
	<T.MeshBasicMaterial color={[1, 0, 0]} />
</T.Mesh>

<!-- This should be on a timer to generate 2 cylinders
 Minimum gap between cylinders must exist, and then it expands to fill height
 It should get spawned outside of render, but.-->
<T.Mesh position.x={xAcc + 7} position.y={1} position.z={0}>
	<T.CylinderGeometry args={[0.4, 0.4, 2]} />
	<T.MeshBasicMaterial color={[1, 0, 1]} />
</T.Mesh>
