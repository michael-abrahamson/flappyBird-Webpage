<script lang="ts">
	import { T, useRender, useThrelte, useFrame, useTask } from '@threlte/core';
	import {
		ContactShadows,
		Float,
		Grid,
		OrbitControls,
		Instance,
		InstancedMesh,
		useTexture,
		Text
	} from '@threlte/extras';
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
	import * as THREE from 'three';
	import { onMount } from 'svelte';
	import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
	import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
	import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
	import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
	import { damp, degToRad } from 'three/src/math/MathUtils.js';
	import JediStarFighter from './models/scene.svelte';
	import Asteroid from './models/asteroid.svelte';
	import { ThreeMFLoader } from 'three/examples/jsm/Addons.js';

	let planeRef: any; //check intersection with objects
	let player: any; //Bird
	let pillarRef: any; //obstacles
	let groundRef: any; //ground plane
	let ceilingRef: any; //ceiling plane

	const { scene, camera, renderer } = useThrelte();

	scene.background = new Color('#02040A');
	scene.fog = new THREE.Fog('#02040A', 8, 35);

	const composer = new EffectComposer(renderer);
	composer.setSize(innerWidth, innerHeight);

	const setupEffectComposer = () => {
		const renderPass = new RenderPass(scene, camera.current);
		composer.addPass(renderPass);

		const bloomPass = new UnrealBloomPass(new Vector2(innerWidth, innerHeight), 0.6, 0.81, 0.15);
		composer.addPass(bloomPass);

		const outputPass = new OutputPass();
		composer.addPass(outputPass);
	};

	useRender(({ scene }) => {
		composer.render();
	});

	//handle spawning of obstacles
	let obstacleSpawnTimer = 0;
	let obstacleSpawnInterval = 2; //seconds
	let obstacles: any[] = [];
	const obstacleSpeed = 5; //units per second

	// Handling y level of pipe spawning + gap
	const PIPE_GAP = 3;
	const MAX_Y = 3.6;
	const MIN_Y = -3.2;
	const PIPE_HEIGHT = 10;

	const PLAYER_RADIUS = 0.35;

	// Pipe collision size
	const PIPE_RADIUS = 0.45;
	const PIPE_HALF_HEIGHT = PIPE_HEIGHT / 2;

	const MIN_GAP_CENTER = MIN_Y + PIPE_GAP / 2;

	const MAX_GAP_CENTER = MAX_Y - PIPE_GAP / 2;

	function spawnObstacles() {
		// Handling Position of Center Gap
		const gapCenterY = randomRange(MIN_GAP_CENTER, MAX_GAP_CENTER);
		const bottomPipeY = gapCenterY - PIPE_GAP / 2 - PIPE_HEIGHT / 2; // /2 to account for half height of pipes
		const topPipeY = gapCenterY + PIPE_GAP / 2 + PIPE_HEIGHT / 2;

		let topPipe = {
			pos: new Vector3(15, topPipeY, 0),
			speed: obstacleSpeed,
			color: new Color('#228B22'),
			len: new Vector3(1, 1, 1)
		};
		let bottomPipe = {
			pos: new Vector3(15, bottomPipeY, 0),
			speed: obstacleSpeed,
			color: new Color('#228B22'),
			len: new Vector3(1, 1, 1)
		};

		obstacles.push(topPipe);
		obstacles.push(bottomPipe);
	}
	/**
	 * Box surrounding player (HitBox)
	 */
	function getPlayerAABB() {
		return {
			minX: -1 - PLAYER_RADIUS,
			maxX: -1 + PLAYER_RADIUS,
			minY: y - PLAYER_RADIUS,
			maxY: y + PLAYER_RADIUS
		};
	}
	/**
	 * Hit Box for pipes
	 * @param pipe
	 */
	function getPipeAABB(pipe: any) {
		return {
			minX: pipe.pos.x - PIPE_RADIUS,
			maxX: pipe.pos.x + PIPE_RADIUS,
			minY: pipe.pos.y - PIPE_HALF_HEIGHT,
			maxY: pipe.pos.y + PIPE_HALF_HEIGHT
		};
	}
	/**
	 * If player collides with pipe
	 * @param a
	 * @param b
	 */
	function aabbIntersect(a: any, b: any) {
		return a.minX < b.maxX && a.maxX > b.minX && a.minY < b.maxY && a.maxY > b.minY;
	}

	const gravityAcc = -30;
	const upwardAcc = 20;

	//spring damping -> s.t we do not just teleport the player but, it has a smooth motion over time
	let yVel = 0; //velocity
	let y = 1; //position
	const damping = 0.9;

	useTask((delta) => {
		//ran every frame -> used for game logic, can be throttled
		updatePlayerYPos(delta);
		updatePlayerTilt(delta);
		collisionDetection();

		obstacleSpawnTimer += delta;
		if (obstacleSpawnTimer >= obstacleSpawnInterval) {
			spawnObstacles();
			obstacleSpawnTimer = 0;
		}

		obstacles.forEach((obstacle) => {
			obstacle.pos.x -= obstacle.speed * delta;
			if (obstacle.pos.x <= -10) {
				removeObstacle(obstacles.indexOf(obstacle));
			}
		});
		obstacles = obstacles;
		stars.forEach((star) => {
			star.pos.x += star.speed * delta;

			// Below creates a tunnel like effect, pulling the stars towards the camera
			star.pos.y *= 0.995;
			star.pos.z += star.speed * delta * 0.15;

			if (star.pos.x > 17) resetStar(star);

			star.speed = THREE.MathUtils.damp(star.speed, 30, 2, delta);
		});
		stars = stars;
	});
	onMount(() => {
		//this section only runs once on creation
		setupEffectComposer();
	});

	function removeObstacle(index: number) {
		obstacles.splice(index, 1);
	}

	function updatePlayerYPos(delta: number) {
		yVel += gravityAcc * delta;

		yVel *= damping;

		y += yVel * delta;
	}

	function collisionDetection() {
		// basic collision detection between player + obstacles
		//const playerBox = new THREE.Box3().setFromObject(player); //expensive, better to use AABB

		// Check collision with ground and ceiling
		const playerBox = getPlayerAABB();

		// Ground / ceiling
		if (playerBox.minY < MIN_Y || playerBox.maxY > MAX_Y) {
			console.log('collided with ground/ceiling');
			gameOver();
			return;
		}

		// Pipes
		for (const obstacle of obstacles) {
			const pipeBox = getPipeAABB(obstacle);

			if (aabbIntersect(playerBox, pipeBox)) {
				console.log('collided with pipe');
				gameOver();
				return;
			}
		}
	}

	function gameOver() {
		console.log('GAME OVER');

		yVel = 0;
		obstacles.length = 0;
		y = 1;

		//pause Game or restart or showUI -> TBD
	}
	const MAX_TILT = degToRad(30);
	const TILT_SPEED = 6;
	let tiltGroup: THREE.Group;

	function updatePlayerTilt(delta: number) {
		// tilt the player based on yVel
		if (!tiltGroup) return;

		//normalize vector to [-1, 1]
		const velNorm = THREE.MathUtils.clamp(yVel / upwardAcc, -1, 1);
		const targetTilt = yVel > 0 ? velNorm * MAX_TILT : velNorm * MAX_TILT * 0.6;
		// negative -> up is nose up

		//smooth interpolation
		tiltGroup.rotation.z = damp(tiltGroup.rotation.z, targetTilt, TILT_SPEED, delta);
	}

	/**
	 * On keyboard "space" click, an upward velocity is added to the yVel
	 * Spring motion must be added such that there is a stiffness and damping
	 * @param event
	 */
	function onClick(event: any) {
		yVel += upwardAcc;

		stars.forEach((star) => {
			star.speed *= 1.2;
			star.len *= 1.1;
		});
	}
	function handleKeyDown(event: any) {
		yVel += upwardAcc;

		stars.forEach((star) => {
			star.speed *= 1.2;
			star.len *= 1.1;
		});
	}

	/**
	 * Generates a random number between min and max
	 * @param min
	 * @param max
	 */
	function randomRange(min: number, max: number) {
		return Math.random() * (max - min) + min;
	}

	// section where we will generate stars i.e the light flashes decorating the scene
	let colors = ['#EAF6FF', '#CDEBFF', '#9FD6FF', '#5FB8FF', '#2F9BFF'];

	const MAX_STARS = 800;
	let stars: any[] = [];
	for (let i = 0; i < MAX_STARS; i++) {
		let star = {
			pos: null,
			len: null,
			color: null,
			speed: null,
			thickness: null
		};

		stars.push(resetStar(star));
	}

	/**
	 * Here we will provide the stars with values
	 * @param star
	 */
	function resetStar(star: any) {
		star.pos = new Vector3(randomRange(-15, -45), randomRange(-6, 8), randomRange(-10, -80));

		const depth = THREE.MathUtils.mapLinear(star.pos.z, -10, -80, 1, 0);

		star.len = randomRange(1, 2) * depth;
		star.thickness = randomRange(0.1, 0.2) * depth;

		star.speed = randomRange(20, 30) * depth;
		star.rad = randomRange(0.001, 0.002);
		star.color = new Color(colors[Math.floor(Math.random() * colors.length)])
			.convertSRGBToLinear()
			.multiplyScalar(1.6);
		return star;
	}
</script>

<svelte:window on:keydown={handleKeyDown} on:click={onClick} />

<T.PerspectiveCamera
	makeDefault
	position.x={4}
	position.y={0}
	position.z={8}
	fov={50}
	enableZoom={false}
	enablePan={false}
></T.PerspectiveCamera>
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
	// invisible plane for raycasting
	<T.PlaneGeometry args={[20, 20]} />
	<T.MeshBasicMaterial color={[1, 0, 1]} transparent opacity={0.25} />
</T.Mesh>

<T.Mesh
	visible={false}
	bind:ref={groundRef}
	position={[0, -3.2, 0]}
	rotation={[-Math.PI / 2, 0, 0]}
>
	<T.PlaneGeometry args={[50, 1]} />
	<T.MeshBasicMaterial color={[0.1, 0.2, 0.1]} />
</T.Mesh> //plane for ground layer

<T.Mesh visible={false} bind:ref={ceilingRef} position={[0, 3.6, 0]} rotation={[Math.PI / 2, 0, 0]}>
	<T.PlaneGeometry args={[50, 1]} />
	<T.MeshBasicMaterial color={[0.1, 0.1, 0.1]} />
</T.Mesh> //plane for ceiling layer

{#each obstacles as obstacle}
	// pillars /obstacles
	<T.Mesh position={[obstacle.pos.x, obstacle.pos.y, obstacle.pos.z]}>
		<T.CylinderGeometry args={[0.45, 0.45, PIPE_HEIGHT]} />
		<T.MeshBasicMaterial color={obstacle.color} metalness={0.8} roughness={0.3} />
		<T.CylinderGeometry args={[0.35, 0.35, PIPE_HEIGHT * 0.98]} />
		<T.MeshBasicMaterial color="#4fd3ff" transparent opacity={0.85} />
	</T.Mesh>
{/each}
<T.Group bind:ref={player} position={[-1, y, 0]}>
	<T.Group bind:ref={tiltGroup}>
		<!-- <T.AxesHelper args={[2]} /> -->
		<T.Group>
			<JediStarFighter scale={0.4} rotation={[0, -Math.PI / 2, -Math.PI / 2]} />
		</T.Group>
	</T.Group>
</T.Group>

<InstancedMesh limit={MAX_STARS} range={MAX_STARS}>
	<T.PlaneGeometry args={[1, 0.05]} />
	<T.MeshBasicMaterial transparent depthWrite={false} />

	{#each stars as star}
		<Instance
			position={[star.pos.x, star.pos.y, star.pos.z]}
			scale={[star.len, star.thickness, 1]}
			color={star.color}
		/>
	{/each}
</InstancedMesh>
