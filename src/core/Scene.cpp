/*
 * MIT License
 *
 * Copyright(c) 2019 Asif Ali
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#define STB_IMAGE_RESIZE_IMPLEMENTATION

#include <iostream>
#include <vector>
#include "stb_image_resize.h"
#include "stb_image.h"
#include "Scene.h"
#include "Camera.h"
#include <array>
using Face = std::array<Vec3, 4>;

namespace GLSLPT
{
    std::array<Vec3, 8> computeCorners(const Vec3& min, const Vec3& max) {
        return {{
            {min[0], min[1], min[2]}, // 0: minX, minY, minZ
            {max[0], min[1], min[2]}, // 1: maxX, minY, minZ
            {max[0], max[1], min[2]}, // 2: maxX, maxY, minZ
            {min[0], max[1], min[2]}, // 3: minX, maxY, minZ
            {min[0], min[1], max[2]}, // 4: minX, minY, maxZ
            {max[0], min[1], max[2]}, // 5: maxX, minY, maxZ
            {max[0], max[1], max[2]}, // 6: maxX, maxY, maxZ
            {min[0], max[1], max[2]}  // 7: minX, maxY, maxZ
        }};
    }

    std::array<Face, 6> computeFaces(const Vec3& min, const Vec3& max) {
        const auto corners = computeCorners(min, max);
    
        // Define faces (using indices into 'corners' array)
        return {{
            // Front face (Z = maxZ)
            {corners[4], corners[5], corners[6], corners[7]},
            // Back face (Z = minZ)
            {corners[0], corners[3], corners[2], corners[1]},
            // Left face (X = minX)
            {corners[0], corners[4], corners[7], corners[3]},
            // Right face (X = maxX)
            {corners[1], corners[2], corners[6], corners[5]},
            // Bottom face (Y = minY)
            {corners[0], corners[1], corners[5], corners[4]},
            // Top face (Y = maxY)
            {corners[3], corners[7], corners[6], corners[2]}
        }};
    }

    Vec3 transformVec(const Vec3& v1, const Mat4& transform) {

        Vec3 transformed_v1(transform.data[0][0] * v1[0] + transform.data[0][1] * v1[1] + transform.data[0][2] * v1[2] + transform.data[0][3],
            transform.data[1][0] * v1[0] + transform.data[1][1] * v1[1] + transform.data[1][2] * v1[2] + transform.data[1][3],
        transform.data[2][0] * v1[0] + transform.data[2][1] * v1[1] + transform.data[2][2] * v1[2] + transform.data[2][3]);

        return transformed_v1;
    }

    Scene::~Scene()
    {
        for (int i = 0; i < meshes.size(); i++)
            delete meshes[i];
        meshes.clear();

        for (int i = 0; i < textures.size(); i++)
            delete textures[i];
        textures.clear();

        if (camera)
            delete camera;

        if (sceneBvh)
            delete sceneBvh;

        if (envMap)
            delete envMap;
    };

    void Scene::AddCamera(Vec3 pos, Vec3 lookAt, float fov)
    {
        delete camera;
        camera = new Camera(pos, lookAt, fov);
    }

    int Scene::AddMesh(const std::string& filename)
    {
        int id = -1;
        // Check if mesh was already loaded
        for (int i = 0; i < meshes.size(); i++)
            if (meshes[i]->name == filename)
                return i;

        id = meshes.size();
        Mesh* mesh = new Mesh;

        printf("Loading model %s\n", filename.c_str());
        if (mesh->LoadFromFile(filename))
            meshes.push_back(mesh);
        else
        {
            printf("Unable to load model %s\n", filename.c_str());
            delete mesh;
            id = -1;
        }
        return id;
    }

    int Scene::AddTexture(const std::string& filename)
    {
        int id = -1;
        // Check if texture was already loaded
        for (int i = 0; i < textures.size(); i++)
            if (textures[i]->name == filename)
                return i;

        id = textures.size();
        Texture* texture = new Texture;

        printf("Loading texture %s\n", filename.c_str());
        if (texture->LoadTexture(filename))
            textures.push_back(texture);
        else
        {
            printf("Unable to load texture %s\n", filename.c_str());
            delete texture;
            id = -1;
        }

        return id;
    }

    int Scene::AddMaterial(const Material& material)
    {
        int id = materials.size();
        materials.push_back(material);
        return id;
    }

    void Scene::AddEnvMap(const std::string& filename)
    {
        if (envMap)
            delete envMap;

        envMap = new EnvironmentMap;
        if (envMap->LoadMap(filename.c_str()))
            printf("HDR %s loaded\n", filename.c_str());
        else
        {
            printf("Unable to load HDR\n");
            delete envMap;
            envMap = nullptr;
        }
        envMapModified = true;
        dirty = true;
    }

    int Scene::AddMeshInstance(const MeshInstance& meshInstance)
    {
        int id = meshInstances.size();
        meshInstances.push_back(meshInstance);
        Vec3 emit = materials[meshInstance.materialID].emission;
        
        bool isLight = false; //GLSLPT::Vec3::Length(emit) > .01;

        if(!isLight) {
            return id;
        }

        Mesh *mesh = meshes[meshInstance.meshID];
        const int numTris = mesh->verticesUVX.size() / 3;
        Mat4 transform = meshInstance.transform;
        
        if(mesh->bvh->GetHeight() == 0) {
            mesh->BuildBVH();
        }
        const auto faces = computeFaces(mesh->bvh->Bounds().pmin, mesh->bvh->Bounds().pmax);

        for(const auto &face : faces) {
            Vec3 v0 = transformVec(face[0], transform);
            Vec3 v1 = transformVec(face[1], transform);
            Vec3 v3 = transformVec(face[3], transform);

            Light light;

            light.type = LightType::RectLight;
            light.position = v0;
            light.v = v3 - light.position;
            light.u = v1 - light.position;
            light.area = Vec3::Length(Vec3::Cross(light.u, light.v));
            if(light.area < 0) {
                Vec3 t = light.v;
                light.v = light.u;
                light.u = t;
                light.area = -light.area;
            }
            light.emission = Vec3(.1, .1, .1) * emit;
            lights.push_back(light);
        }

        /*
        for(int i = 0; i < numTris; i++) {
            Vec3 v1(mesh->verticesUVX[3*i + 0][0], mesh->verticesUVX[3*i + 0][1], mesh->verticesUVX[3*i + 0][2]);
            Vec3 v2(mesh->verticesUVX[3*i + 1][0], mesh->verticesUVX[3*i + 1][1], mesh->verticesUVX[3*i + 1][2]);
            Vec3 v3(mesh->verticesUVX[3*i + 2][0], mesh->verticesUVX[3*i + 2][1], mesh->verticesUVX[3*i + 2][2]);

            Vec3 _v1(transform.data[0][0] * v1[0] + transform.data[0][1] * v1[1] + transform.data[0][2] * v1[2] + transform.data[0][3],
                transform.data[1][0] * v1[0] + transform.data[1][1] * v1[1] + transform.data[1][2] * v1[2] + transform.data[1][3],
            transform.data[2][0] * v1[0] + transform.data[2][1] * v1[1] + transform.data[2][2] * v1[2] + transform.data[2][3]);

            Vec3 _v2(transform.data[0][0] * v2[0] + transform.data[0][1] * v2[1] + transform.data[0][2] * v2[2] + transform.data[0][3],
                transform.data[1][0] * v2[0] + transform.data[1][1] * v2[1] + transform.data[1][2] * v2[2] + transform.data[1][3],
            transform.data[2][0] * v2[0] + transform.data[2][1] * v2[1] + transform.data[2][2] * v2[2] + transform.data[2][3]);

            Vec3 _v3(transform.data[0][0] * v3[0] + transform.data[0][1] * v3[1] + transform.data[0][2] * v3[2] + transform.data[0][3],
                transform.data[1][0] * v3[0] + transform.data[1][1] * v3[1] + transform.data[1][2] * v3[2] + transform.data[1][3],
            transform.data[2][0] * v3[0] + transform.data[2][1] * v3[1] + transform.data[2][2] * v3[2] + transform.data[2][3]);

            Light light;
            light.type = LightType::RectLight;
            light.position = _v1;
            light.v = _v2 - light.position;
            light.u = _v3 - light.position;
            light.area = abs(Vec3::Length(Vec3::Cross(light.u, light.v)));
            light.emission = emit;
            lights.push_back(light);
        }*/

        return id;
    }

    int Scene::AddLight(const Light& light)
    {
        int id = lights.size();
        lights.push_back(light);
        return id;
    }

    void Scene::createTLAS()
    {
        // Loop through all the mesh Instances and build a Top Level BVH
        std::vector<RadeonRays::bbox> bounds;
        bounds.resize(meshInstances.size());

        for (int i = 0; i < meshInstances.size(); i++)
        {
            RadeonRays::bbox bbox = meshes[meshInstances[i].meshID]->bvh->Bounds();
            Mat4 matrix = meshInstances[i].transform;

            Vec3 minBound = bbox.pmin;
            Vec3 maxBound = bbox.pmax;

            Vec3 right       = Vec3(matrix[0][0], matrix[0][1], matrix[0][2]);
            Vec3 up          = Vec3(matrix[1][0], matrix[1][1], matrix[1][2]);
            Vec3 forward     = Vec3(matrix[2][0], matrix[2][1], matrix[2][2]);
            Vec3 translation = Vec3(matrix[3][0], matrix[3][1], matrix[3][2]);

            Vec3 xa = right * minBound.x;
            Vec3 xb = right * maxBound.x;

            Vec3 ya = up * minBound.y;
            Vec3 yb = up * maxBound.y;

            Vec3 za = forward * minBound.z;
            Vec3 zb = forward * maxBound.z;

            minBound = Vec3::Min(xa, xb) + Vec3::Min(ya, yb) + Vec3::Min(za, zb) + translation;
            maxBound = Vec3::Max(xa, xb) + Vec3::Max(ya, yb) + Vec3::Max(za, zb) + translation;

            RadeonRays::bbox bound;
            bound.pmin = minBound;
            bound.pmax = maxBound;

            bounds[i] = bound;
        }
        sceneBvh->Build(&bounds[0], bounds.size());
        sceneBounds = sceneBvh->Bounds();
    }

    void Scene::createBLAS()
    {
        // Loop through all meshes and build BVHs
#pragma omp parallel for
        for (int i = 0; i < meshes.size(); i++)
        {
            printf("Building BVH for %s\n", meshes[i]->name.c_str());
            meshes[i]->BuildBVH();
        }
    }

    void Scene::RebuildInstances()
    {
        delete sceneBvh;
        sceneBvh = new RadeonRays::Bvh(10.0f, 64, false);

        createTLAS();
        bvhTranslator.UpdateTLAS(sceneBvh, meshInstances);

        //Copy transforms
        for (int i = 0; i < meshInstances.size(); i++)
            transforms[i] = meshInstances[i].transform;

        instancesModified = true;
        dirty = true;
    }

    void Scene::ProcessScene()
    {
        printf("Processing scene data\n");
        createBLAS();

        printf("Building scene BVH\n");
        createTLAS();

        // Flatten BVH
        printf("Flattening BVH\n");
        bvhTranslator.Process(sceneBvh, meshes, meshInstances);

        // Copy mesh data
        int verticesCnt = 0;
        printf("Copying Mesh Data\n");
        for (int i = 0; i < meshes.size(); i++)
        {
            // Copy indices from BVH and not from Mesh. 
            // Required if splitBVH is used as a triangle can be shared by leaf nodes
            int numIndices = meshes[i]->bvh->GetNumIndices();
            const int* triIndices = meshes[i]->bvh->GetIndices();

            for (int j = 0; j < numIndices; j++)
            {
                int index = triIndices[j];
                int v1 = (index * 3 + 0) + verticesCnt;
                int v2 = (index * 3 + 1) + verticesCnt;
                int v3 = (index * 3 + 2) + verticesCnt;

                vertIndices.push_back(Indices{ v1, v2, v3 });
            }

            verticesUVX.insert(verticesUVX.end(), meshes[i]->verticesUVX.begin(), meshes[i]->verticesUVX.end());
            normalsUVY.insert(normalsUVY.end(), meshes[i]->normalsUVY.begin(), meshes[i]->normalsUVY.end());

            verticesCnt += meshes[i]->verticesUVX.size();
        }

        // Copy transforms
        printf("Copying transforms\n");
        transforms.resize(meshInstances.size());
        for (int i = 0; i < meshInstances.size(); i++)
            transforms[i] = meshInstances[i].transform;

        // Copy textures
        if (!textures.empty())
            printf("Copying and resizing textures\n");

        int reqWidth = renderOptions.texArrayWidth;
        int reqHeight = renderOptions.texArrayHeight;
        int texBytes = reqWidth * reqHeight * 4;
        textureMapsArray.resize(texBytes * textures.size());

#pragma omp parallel for
        for (int i = 0; i < textures.size(); i++)
        {
            int texWidth = textures[i]->width;
            int texHeight = textures[i]->height;

            // Resize textures to fit 2D texture array
            if (texWidth != reqWidth || texHeight != reqHeight)
            {
                unsigned char* resizedTex = new unsigned char[texBytes];
                stbir_resize_uint8(&textures[i]->texData[0], texWidth, texHeight, 0, resizedTex, reqWidth, reqHeight, 0, 4);
                std::copy(resizedTex, resizedTex + texBytes, &textureMapsArray[i * texBytes]);
                delete[] resizedTex;
            }
            else
                std::copy(textures[i]->texData.begin(), textures[i]->texData.end(), &textureMapsArray[i * texBytes]);
        }

        // Add a default camera
        if (!camera)
        {
            RadeonRays::bbox bounds = sceneBvh->Bounds();
            Vec3 extents = bounds.extents();
            Vec3 center = bounds.center();
            AddCamera(Vec3(center.x, center.y, center.z + 3.0f), center, 45.0f);
        }

        initialized = true;
    }
}