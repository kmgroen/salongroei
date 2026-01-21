#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "google-genai>=1.46.0",
#     "python-dotenv>=1.0.0",
#     "pillow>=10.0.0",
# ]
# ///
"""
Generate images using Google's image generation models.

Supported models:
- nano-banana-pro: Gemini 3 Pro Image Preview - best quality, text rendering, $0.134/image
- nano-banana: Gemini 2.5 Flash Image - fast, supports references, $0.039/image
- imagen-4 (default): Imagen 4 - high quality, $0.04/image
- imagen-3: Imagen 3 - good quality, $0.03/image

Used to create frames for video generation with Veo 3.1.
"""

import os
import sys
import argparse
import base64
from pathlib import Path
from typing import List, Optional
from datetime import datetime
from google import genai
from google.genai import types
from PIL import Image
from io import BytesIO
from dotenv import load_dotenv

# Load environment variables from project root and backend
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
load_dotenv(PROJECT_ROOT / ".env")
load_dotenv(PROJECT_ROOT / "backend" / "project" / ".env")  # Also check backend .env


class GeminiImageGenerator:
    """Generate images using Google's image generation models."""

    # Model configurations with pricing
    MODELS = {
        'nano-banana-pro': {
            'id': 'gemini-3-pro-image-preview',
            'cost': 0.134,  # $0.134 for 1K/2K, $0.24 for 4K
            'cost_4k': 0.24,
            'description': 'Nano Banana Pro (Gemini 3 Pro Image Preview) - best quality, text rendering',
            'supports_size': False,  # API changed - output_resolution not supported
            'api_type': 'gemini',  # Uses generate_content API
        },
        'imagen-4': {
            'id': 'imagen-4.0-generate-001',
            'cost': 0.04,
            'description': 'Imagen 4 - high quality',
            'supports_size': True,
            'api_type': 'imagen',  # Uses generate_images API
        },
        'imagen-3': {
            'id': 'imagen-3.0-generate-002',
            'cost': 0.03,
            'description': 'Imagen 3 - good quality',
            'supports_size': False,
            'api_type': 'imagen',
        },
        'nano-banana': {
            'id': 'gemini-2.5-flash-image',
            'cost': 0.039,
            'description': 'Nano Banana (Gemini 2.5 Flash Image) - fast, supports references',
            'supports_size': False,
            'api_type': 'gemini',
        },
    }

    DEFAULT_MODEL = 'imagen-4'

    # Size configurations
    SIZES = {
        '1K': '1K',      # 1024px on longest side
        '2K': '2K',      # 2048px on longest side
        '4K': '4K',      # 4096px on longest side
        'default': None,  # Model default
    }

    def __init__(
        self,
        api_key: Optional[str] = None,
        project_id: Optional[str] = None,
        output_dir: str = "./generated_images",
        model: str = DEFAULT_MODEL
    ):
        """
        Initialize image generator.

        Args:
            api_key: Google AI Studio API key (uses env var if not provided)
            project_id: Google Cloud project ID (for Vertex AI)
            output_dir: Directory to save generated images
            model: Model to use ('imagen-4', 'imagen-3', or 'gemini-flash')
        """
        # Try image-specific key first, then GEMINI_API_KEY, then generic key
        self.api_key = api_key or os.getenv('GOOGLE_API_KEY_IMAGES') or os.getenv('GEMINI_API_KEY') or os.getenv('GOOGLE_API_KEY')
        self.project_id = project_id or os.getenv('GOOGLE_CLOUD_PROJECT')

        if not self.api_key and not self.project_id:
            raise ValueError(
                "Either GOOGLE_API_KEY_IMAGES (or GOOGLE_API_KEY) or GOOGLE_CLOUD_PROJECT must be set"
            )

        # Validate and set model
        if model not in self.MODELS:
            raise ValueError(f"Unknown model: {model}. Available: {list(self.MODELS.keys())}")
        self.model = model
        self.model_config = self.MODELS[model]

        # Initialize client
        if self.api_key:
            self.client = genai.Client(api_key=self.api_key)
        else:
            self.client = genai.Client()  # Uses default credentials

        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        print(f"✓ Image Generator initialized")
        print(f"  Model: {self.model_config['id']} ({self.model_config['description']})")
        print(f"  Output directory: {self.output_dir}")
        print(f"  Cost per image: ${self.model_config['cost']:.3f}")

    def generate_image(
        self,
        prompt: str,
        aspect_ratio: str = "1:1",
        image_size: str = "2K",
        reference_images: Optional[List[str]] = None,
        output_filename: Optional[str] = None,
        return_base64: bool = False
    ) -> dict:
        """
        Generate a single image from text prompt.

        Args:
            prompt: Text description of desired image
            aspect_ratio: Image aspect ratio (1:1, 16:9, 9:16, 3:4, 4:3 for Imagen; more for Gemini)
            image_size: Image size for Imagen 4 ('2K' or '4K', ignored for other models)
            reference_images: Optional list of reference image paths to guide generation
            output_filename: Custom filename (auto-generated if None)
            return_base64: Return base64-encoded image data

        Returns:
            Dictionary with image_path, cost, and optionally base64_data
        """
        print(f"\n🎨 Generating image with {self.model_config['id']}: {prompt[:60]}...")
        print(f"   Aspect ratio: {aspect_ratio}")
        if self.model_config['supports_size']:
            print(f"   Image size: {image_size}")
        if reference_images:
            print(f"   Reference images: {len(reference_images)}")

        try:
            # Route to appropriate generation method based on api_type
            if self.model_config.get('api_type') == 'gemini':
                image_data = self._generate_with_gemini(prompt, aspect_ratio, image_size, reference_images)
            else:
                image_data = self._generate_with_imagen(prompt, aspect_ratio, image_size)

            image = Image.open(BytesIO(image_data))

            # Generate filename if not provided
            if not output_filename:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                # Sanitize prompt for filename
                safe_prompt = "".join(c for c in prompt[:30] if c.isalnum() or c in (' ', '-', '_')).strip()
                safe_prompt = safe_prompt.replace(' ', '_')
                output_filename = f"img_{timestamp}_{safe_prompt}.png"

            # Save image
            output_path = self.output_dir / output_filename
            image.save(output_path, format='PNG')

            print(f"✓ Image saved: {output_path}")
            print(f"  Resolution: {image.size[0]}×{image.size[1]}")
            print(f"  Cost: ${self.model_config['cost']:.3f}")

            result = {
                'success': True,
                'image_path': str(output_path),
                'resolution': f"{image.size[0]}×{image.size[1]}",
                'cost': self.model_config['cost'],
                'aspect_ratio': aspect_ratio,
                'model': self.model_config['id']
            }

            if return_base64:
                result['base64_data'] = base64.b64encode(image_data).decode('utf-8')

            return result

        except Exception as e:
            print(f"✗ Error generating image: {e}")
            return {
                'success': False,
                'error': str(e)
            }

    def _generate_with_imagen(
        self,
        prompt: str,
        aspect_ratio: str,
        image_size: str
    ) -> bytes:
        """Generate image using Imagen 3 or 4 API."""
        # Build config for Imagen models
        config_params = {
            'number_of_images': 1,
            'aspect_ratio': aspect_ratio,
        }

        # Add image_size for Imagen 4
        if self.model_config['supports_size'] and image_size in self.SIZES:
            size_value = self.SIZES[image_size]
            if size_value:
                config_params['image_size'] = size_value

        config = types.GenerateImagesConfig(**config_params)

        response = self.client.models.generate_images(
            model=self.model_config['id'],
            prompt=prompt,
            config=config
        )

        if not response.generated_images:
            raise Exception("No image generated")

        # Get image bytes from response
        generated_image = response.generated_images[0]
        return generated_image.image.image_bytes

    def _generate_with_gemini(
        self,
        prompt: str,
        aspect_ratio: str,
        image_size: str = "2K",
        reference_images: Optional[List[str]] = None
    ) -> bytes:
        """Generate image using Gemini API (Nano Banana or Nano Banana Pro)."""
        # Build contents list with prompt and optional reference images
        contents = []

        # Add reference images first if provided
        if reference_images:
            for ref_path in reference_images:
                with open(ref_path, 'rb') as f:
                    image_data = f.read()
                mime_type = 'image/png' if ref_path.endswith('.png') else 'image/jpeg'
                ref_part = types.Part.from_bytes(
                    data=image_data,
                    mime_type=mime_type
                )
                contents.append(ref_part)

        # Add text prompt
        contents.append(prompt)

        # Build image config
        image_config_params = {'aspect_ratio': aspect_ratio}

        # Add output_resolution for models that support it (Nano Banana Pro)
        if self.model_config['supports_size'] and image_size in self.SIZES:
            size_value = self.SIZES[image_size]
            if size_value:
                image_config_params['output_resolution'] = size_value

        # Configure for image-only output
        config = types.GenerateContentConfig(
            image_config=types.ImageConfig(**image_config_params),
            response_modalities=['Image']
        )

        # Generate image
        response = self.client.models.generate_content(
            model=self.model_config['id'],
            contents=contents,
            config=config
        )

        # Extract image from response
        if not response.candidates:
            raise Exception("No image generated")

        image_part = None
        for part in response.candidates[0].content.parts:
            if hasattr(part, 'inline_data'):
                image_part = part
                break

        if not image_part:
            raise Exception("No image data in response")

        # Decode image - handle both base64 string and bytes
        if hasattr(image_part.inline_data, 'data'):
            image_data = image_part.inline_data.data
            # If it's a string, decode from base64
            if isinstance(image_data, str):
                image_data = base64.b64decode(image_data)
            return image_data
        else:
            raise Exception("Invalid image data format in response")

    def generate_multiple_images(
        self,
        prompts: List[str],
        aspect_ratio: str = "16:9",
        image_size: str = "2K",
        prefix: str = "frame"
    ) -> List[dict]:
        """
        Generate multiple images from a list of prompts.

        Args:
            prompts: List of text prompts
            aspect_ratio: Aspect ratio for all images
            image_size: Image size for Imagen 4 ('2K' or '4K')
            prefix: Filename prefix

        Returns:
            List of result dictionaries
        """
        results = []
        total_cost = 0

        print(f"\n🎨 Generating {len(prompts)} images with {self.model_config['id']}...")
        print(f"   Aspect ratio: {aspect_ratio}")
        if self.model_config['supports_size']:
            print(f"   Image size: {image_size}")
        print(f"   Estimated cost: ${len(prompts) * self.model_config['cost']:.2f}")

        for i, prompt in enumerate(prompts, 1):
            print(f"\n[{i}/{len(prompts)}] Generating frame {i}...")

            filename = f"{prefix}_{i:02d}.png"
            result = self.generate_image(
                prompt=prompt,
                aspect_ratio=aspect_ratio,
                image_size=image_size,
                output_filename=filename
            )

            results.append(result)

            if result['success']:
                total_cost += result['cost']

        successful = sum(1 for r in results if r['success'])
        print(f"\n✓ Generated {successful}/{len(prompts)} images")
        print(f"  Total cost: ${total_cost:.2f}")

        return results

    def edit_image(
        self,
        image_path: str,
        edit_prompt: str,
        output_filename: Optional[str] = None
    ) -> dict:
        """
        Edit an existing image using conversational editing.

        Args:
            image_path: Path to input image
            edit_prompt: Description of desired changes
            output_filename: Custom output filename

        Returns:
            Result dictionary
        """
        print(f"\n✏️  Editing image: {image_path}")
        print(f"   Edit: {edit_prompt}")

        try:
            # Load input image
            with open(image_path, 'rb') as f:
                image_data = f.read()

            image_b64 = base64.b64encode(image_data).decode('utf-8')

            # Create image part
            image_part = types.Part.from_bytes(
                data=image_data,
                mime_type="image/png"
            )

            # Configure for image output
            config = types.GenerateContentConfig(
                response_modalities=['Image']
            )

            # Generate edited image
            response = self.client.models.generate_content(
                model="gemini-2.5-flash-image",
                contents=[image_part, edit_prompt],
                config=config
            )

            # Extract edited image
            if not response.candidates:
                raise Exception("No edited image generated")

            edited_image_part = None
            for part in response.candidates[0].content.parts:
                if hasattr(part, 'inline_data'):
                    edited_image_part = part
                    break

            if not edited_image_part:
                raise Exception("No image data in response")

            # Decode and save
            edited_data = base64.b64decode(edited_image_part.inline_data.data)
            edited_image = Image.open(BytesIO(edited_data))

            if not output_filename:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                output_filename = f"edited_{timestamp}.png"

            output_path = self.output_dir / output_filename
            edited_image.save(output_path, format='PNG')

            print(f"✓ Edited image saved: {output_path}")
            print(f"  Cost: ${self.COST_PER_IMAGE:.3f}")

            return {
                'success': True,
                'image_path': str(output_path),
                'cost': self.COST_PER_IMAGE
            }

        except Exception as e:
            print(f"✗ Error editing image: {e}")
            return {
                'success': False,
                'error': str(e)
            }

    def generate_frames_for_video(
        self,
        scene_descriptions: List[str],
        aspect_ratio: str = "16:9",
        image_size: str = "2K",
        style: str = "professional, clean, modern"
    ) -> List[dict]:
        """
        Generate a sequence of frames for video animation.

        Args:
            scene_descriptions: List of scene descriptions
            aspect_ratio: Frame aspect ratio (16:9 recommended for video)
            image_size: Image size for Imagen 4 ('2K' or '4K')
            style: Visual style to apply to all frames

        Returns:
            List of result dictionaries with frame paths
        """
        print(f"\n🎬 Generating {len(scene_descriptions)} video frames...")
        print(f"   Style: {style}")
        print(f"   Aspect ratio: {aspect_ratio}")

        # Add style to each prompt
        styled_prompts = [
            f"{desc}, {style}" for desc in scene_descriptions
        ]

        results = self.generate_multiple_images(
            prompts=styled_prompts,
            aspect_ratio=aspect_ratio,
            image_size=image_size,
            prefix="video_frame"
        )

        return results


def main():
    """Command-line interface for image generation."""
    parser = argparse.ArgumentParser(
        description="Generate images using Google's image generation models (Imagen 4, Imagen 3, or Gemini Flash)"
    )

    parser.add_argument(
        '--prompt',
        type=str,
        help='Image generation prompt'
    )
    parser.add_argument(
        '--model',
        type=str,
        default='imagen-4',
        choices=['imagen-4', 'imagen-3', 'nano-banana-pro', 'nano-banana'],
        help='Model to use (default: imagen-4). nano-banana-pro has best text rendering but costs more'
    )
    parser.add_argument(
        '--size',
        type=str,
        default='2K',
        choices=['1K', '2K', '4K'],
        help='Image size (default: 2K). 4K costs more for nano-banana-pro ($0.24 vs $0.134)'
    )
    parser.add_argument(
        '--reference-images',
        type=str,
        nargs='+',
        help='Reference image paths to guide generation (only works with gemini-flash model)'
    )
    parser.add_argument(
        '--prompts-file',
        type=str,
        help='File containing multiple prompts (one per line)'
    )
    parser.add_argument(
        '--aspect-ratio',
        type=str,
        default='1:1',
        choices=['1:1', '16:9', '9:16', '3:4', '4:3', '3:2', '2:3', '21:9', '9:21'],
        help='Image aspect ratio (default: 1:1). Note: Imagen models only support 1:1, 16:9, 9:16, 3:4, 4:3'
    )
    parser.add_argument(
        '--output-dir',
        type=str,
        default='./generated_images',
        help='Output directory for images'
    )
    parser.add_argument(
        '--output',
        type=str,
        help='Custom output filename'
    )
    parser.add_argument(
        '--edit',
        type=str,
        help='Path to image to edit (only works with gemini-flash model)'
    )
    parser.add_argument(
        '--edit-prompt',
        type=str,
        help='Edit instructions (required with --edit)'
    )
    parser.add_argument(
        '--style',
        type=str,
        default='professional, clean, modern',
        help='Visual style for frames'
    )

    args = parser.parse_args()

    # Validate arguments
    if not args.prompt and not args.prompts_file and not args.edit:
        parser.error("Must provide --prompt, --prompts-file, or --edit")

    if args.edit and not args.edit_prompt:
        parser.error("--edit requires --edit-prompt")

    # Reference images work with Gemini-based models (nano-banana, nano-banana-pro)
    gemini_models = ['nano-banana', 'nano-banana-pro']
    if args.reference_images and args.model not in gemini_models:
        print("⚠️  Warning: Reference images only work with Gemini models. Switching to nano-banana-pro.")
        args.model = 'nano-banana-pro'

    if args.edit and args.model not in gemini_models:
        print("⚠️  Warning: Image editing only works with Gemini models. Switching to nano-banana.")
        args.model = 'nano-banana'

    # Initialize generator
    try:
        generator = GeminiImageGenerator(output_dir=args.output_dir, model=args.model)
    except ValueError as e:
        print(f"✗ Error: {e}")
        print("\nSet GOOGLE_API_KEY_IMAGES environment variable:")
        print("  export GOOGLE_API_KEY_IMAGES='your_api_key'")
        print("\nOr use the generic GOOGLE_API_KEY:")
        print("  export GOOGLE_API_KEY='your_api_key'")
        sys.exit(1)

    # Execute based on mode
    if args.edit:
        # Image editing mode
        result = generator.edit_image(
            image_path=args.edit,
            edit_prompt=args.edit_prompt,
            output_filename=args.output
        )

        if result['success']:
            print(f"\n✓ Success! Edited image: {result['image_path']}")
            sys.exit(0)
        else:
            print(f"\n✗ Failed: {result['error']}")
            sys.exit(1)

    elif args.prompts_file:
        # Multiple images mode
        with open(args.prompts_file, 'r') as f:
            prompts = [line.strip() for line in f if line.strip()]

        results = generator.generate_frames_for_video(
            scene_descriptions=prompts,
            aspect_ratio=args.aspect_ratio,
            image_size=args.size,
            style=args.style
        )

        successful = sum(1 for r in results if r['success'])
        print(f"\n✓ Generated {successful}/{len(results)} frames")

        # Print frame paths
        print("\nGenerated frames:")
        for i, result in enumerate(results, 1):
            if result['success']:
                print(f"  {i}. {result['image_path']}")

        sys.exit(0 if successful == len(results) else 1)

    else:
        # Single image mode
        result = generator.generate_image(
            prompt=args.prompt,
            aspect_ratio=args.aspect_ratio,
            image_size=args.size,
            reference_images=args.reference_images,
            output_filename=args.output
        )

        if result['success']:
            print(f"\n✓ Success! Image: {result['image_path']}")
            sys.exit(0)
        else:
            print(f"\n✗ Failed: {result['error']}")
            sys.exit(1)


if __name__ == '__main__':
    main()
