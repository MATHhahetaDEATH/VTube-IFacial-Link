using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

namespace IconGenerator
{
    class Program
    {
        static void Main(string[] args)
        {
            string sourcePath = "app_icon.png";
            string outputPath = "app_icon.ico";

            if (!File.Exists(sourcePath))
            {
                Console.WriteLine($"Error: {sourcePath} not found.");
                return;
            }

            using (Bitmap sourceBitmap = (Bitmap)Image.FromFile(sourcePath))
            {
                int[] sizes = { 16, 32, 48, 64, 128, 256 };
                
                using (FileStream fs = new FileStream(outputPath, FileMode.Create))
                using (BinaryWriter bw = new BinaryWriter(fs))
                {
                    // ICONHEADER (6 bytes)
                    bw.Write((short)0); // Reserved
                    bw.Write((short)1); // Type: Icon
                    bw.Write((short)sizes.Length); // Number of images

                    long entryPos = fs.Position;
                    int dataOffset = 6 + (16 * sizes.Length);

                    // Placeholder for ICONDIRENTRY (16 bytes each)
                    for (int i = 0; i < sizes.Length; i++) bw.Write(new byte[16]);

                    for (int i = 0; i < sizes.Length; i++)
                    {
                        int size = sizes[i];
                        byte[] imageData;

                        using (Bitmap resized = ResizeImage(sourceBitmap, size, size))
                        {
                            using (MemoryStream ms = new MemoryStream())
                            {
                                resized.Save(ms, ImageFormat.Png);
                                imageData = ms.ToArray();
                            }
                        }

                        long currentPos = fs.Position;

                        // Write ICONDIRENTRY
                        fs.Seek(entryPos + (i * 16), SeekOrigin.Begin);
                        bw.Write((byte)(size >= 256 ? 0 : size)); // Width
                        bw.Write((byte)(size >= 256 ? 0 : size)); // Height
                        bw.Write((byte)0); // Color Palette
                        bw.Write((byte)0); // Reserved
                        bw.Write((short)1); // Color Planes
                        bw.Write((short)32); // Bits per pixel
                        bw.Write(imageData.Length); // Data size
                        bw.Write(dataOffset); // Data offset

                        fs.Seek(currentPos, SeekOrigin.Begin);
                        bw.Write(imageData);

                        dataOffset += imageData.Length;
                    }
                }
            }
            Console.WriteLine("app_icon.ico generated successfully.");
        }

        static Bitmap ResizeImage(Image image, int width, int height)
        {
            var destRect = new Rectangle(0, 0, width, height);
            var destImage = new Bitmap(width, height);

            destImage.SetResolution(image.HorizontalResolution, image.VerticalResolution);

            using (var graphics = Graphics.FromImage(destImage))
            {
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.CompositingQuality = CompositingQuality.HighQuality;
                graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                graphics.SmoothingMode = SmoothingMode.HighQuality;
                graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;

                using (var wrapMode = new ImageAttributes())
                {
                    wrapMode.SetWrapMode(WrapMode.TileFlipXY);
                    graphics.DrawImage(image, destRect, 0, 0, image.Width, image.Height, GraphicsUnit.Pixel, wrapMode);
                }
            }
            return destImage;
        }
    }
}
