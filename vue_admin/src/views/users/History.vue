<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <h2>用户病史修改</h2>
    <el-card shadow="always">
      <el-table :data="users" border stripe>
        <el-table-column prop="id_card" label="身份证号" />
        <el-table-column prop="name" label="姓名" />
        <el-table-column prop="allergy_history" label="过敏史">
          <template #default="{ row }"><el-input v-model="row.allergy_history" type="textarea"/></template>
        </el-table-column>
        <el-table-column prop="past_medical_history" label="既往病史">
          <template #default="{ row }"><el-input v-model="row.past_medical_history" type="textarea"/></template>
        </el-table-column>
        <el-table-column prop="is_blacklisted" label="黑名单状态" width="120">
          <template #default="{ row }"><el-switch v-model="row.is_blacklisted" /></template>
        </el-table-column>
        <el-table-column label="操作" width="120">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="handleSave(row)">保存</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import BackButton from '@/components/BackButton.vue';
import { ref } from 'vue';
import { ElMessage } from 'element-plus';

const users = ref([
  { id: '1', id_card: '110...', name: '张三', allergy_history: '无', past_medical_history: '无', is_blacklisted: false },
  { id: '2', id_card: '120...', name: '李四', allergy_history: '青霉素', past_medical_history: '高血压', is_blacklisted: true },
]);

const handleSave = (row) => {
  console.log("Saving:", row);
  ElMessage.success(`用户 ${row.name} 的信息已保存`);
};
</script>

<style scoped>.app-container{padding:20px;}</style>
